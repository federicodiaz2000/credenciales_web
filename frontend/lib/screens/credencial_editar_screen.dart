import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:credenciales_web/classes/credencial.dart';

/// Pantalla para agregar o editar una credencial simple.
class CredencialEditarScreen extends StatefulWidget {
  final int? credencialId;

  const CredencialEditarScreen({super.key, this.credencialId});

  @override
  State<CredencialEditarScreen> createState() => _CredencialEditarScreenState();
}

class _CredencialEditarScreenState extends State<CredencialEditarScreen> {
  bool get _esNuevo => widget.credencialId == null;

  bool _loading = true;
  bool _guardando = false;
  String? _error;

  final _formKey = GlobalKey<FormState>();

  final _ctrlCodigo = TextEditingController();
  final _ctrlDescripcion = TextEditingController();
  final _ctrlUsuario = TextEditingController();
  final _ctrlPassword = TextEditingController();
  final _ctrlNotas = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (_esNuevo) {
      _sugerirCodigo();
    } else {
      _cargar();
    }
  }

  Future<void> _sugerirCodigo() async {
    try {
      final proximo = await Credencial.proximoCodigo();
      if (!mounted) return;
      setState(() {
        _ctrlCodigo.text = proximo.toString();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _ctrlCodigo.dispose();
    _ctrlDescripcion.dispose();
    _ctrlUsuario.dispose();
    _ctrlPassword.dispose();
    _ctrlNotas.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final entidad = await Credencial.consultar(credencialId: widget.credencialId!);
      if (!mounted) return;
      if (entidad == null) {
        setState(() {
          _error = 'No se encontró la credencial ${widget.credencialId}.';
          _loading = false;
        });
        return;
      }
      _ctrlCodigo.text = entidad.credencialId.toString();
      _ctrlDescripcion.text = entidad.descripcion ?? '';
      _ctrlUsuario.text = entidad.usuario ?? '';
      _ctrlPassword.text = entidad.password ?? '';
      _ctrlNotas.text = entidad.notas ?? '';
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar la credencial: $e';
        _loading = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final codigo = int.parse(_ctrlCodigo.text.trim());
      final descripcion = _ctrlDescripcion.text.trim().isNotEmpty ? _ctrlDescripcion.text.trim() : null;
      final usuario = _ctrlUsuario.text.trim().isNotEmpty ? _ctrlUsuario.text.trim() : null;
      final password = _ctrlPassword.text.trim().isNotEmpty ? _ctrlPassword.text.trim() : null;
      final notas = _ctrlNotas.text.trim().isNotEmpty ? _ctrlNotas.text.trim() : null;

      if (_esNuevo) {
        await Credencial.agregar(
          credencialId: codigo,
          descripcion: descripcion,
          usuario: usuario,
          password: password,
          notas: notas,
        );
      } else {
        await Credencial.modificar(
          credencialId: codigo,
          descripcion: descripcion,
          usuario: usuario,
          password: password,
          notas: notas,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esNuevo ? 'Credencial $codigo agregada correctamente.' : 'Credencial $codigo actualizada correctamente.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _esNuevo ? 'Nueva Credencial' : 'Editar Credencial N° ${widget.credencialId}';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _guardando
                  ? const Center(
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : FilledButton.icon(
                      onPressed: _guardar,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar'),
                    ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: const TextStyle(fontSize: 16)),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(
              titulo: 'Datos de la Credencial',
              icono: Icons.description_outlined,
              child: Column(
                children: [
                  _campo(
                    label: 'Código *',
                    controller: _ctrlCodigo,
                    readOnly: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Campo requerido';
                      if (int.tryParse(v.trim()) == null) return 'Debe ser un número entero';
                      return null;
                    },
                    maxLength: 10,
                  ),
                  _campo(label: 'Descripción', controller: _ctrlDescripcion, maxLength: 255),
                  _campo(label: 'Usuario', controller: _ctrlUsuario, maxLength: 255),
                  _campo(label: 'Password', controller: _ctrlPassword, maxLength: 255),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(
              titulo: 'Notas',
              icono: Icons.sticky_note_2_outlined,
              child: _campo(label: 'Notas', controller: _ctrlNotas, maxLines: 6, maxLength: 2000),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: const Icon(Icons.save_outlined),
                label: Text(_esNuevo ? 'Agregar credencial' : 'Guardar cambios'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _card({required String titulo, required IconData icono, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _campo({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hint,
    int? maxLength,
  }) {
    final effectiveFormatters = [
      if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ...?inputFormatters,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        inputFormatters: effectiveFormatters.isEmpty ? null : effectiveFormatters,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
          filled: readOnly,
          fillColor: readOnly ? Colors.grey.shade100 : null,
        ),
      ),
    );
  }
}
