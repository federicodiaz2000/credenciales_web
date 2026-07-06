import 'package:flutter/material.dart';
import 'package:credenciales_web/classes/credencial.dart';

class CredencialConsultaScreen extends StatefulWidget {
  final int credencialId;

  const CredencialConsultaScreen({super.key, required this.credencialId});

  @override
  State<CredencialConsultaScreen> createState() => _CredencialConsultaScreenState();
}

class _CredencialConsultaScreenState extends State<CredencialConsultaScreen> {
  bool _loading = true;
  Credencial? _entidad;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final item = await Credencial.consultar(credencialId: widget.credencialId);
      if (!mounted) return;
      setState(() {
        _entidad = item;
        _error = item == null ? 'No se encontró la credencial ${widget.credencialId}.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar la credencial: $e';
      });
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Credencial N° ${widget.credencialId}')),
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

    final item = _entidad!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _card(
            titulo: 'Datos de la Credencial',
            icono: Icons.description_outlined,
            child: Column(
              children: [
                _campo('Código', item.credencialId.toString()),
                _campo('Descripción', item.descripcion),
                _campo('Usuario', item.usuario),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            titulo: 'Notas',
            icono: Icons.sticky_note_2_outlined,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                (item.notas != null && item.notas!.trim().isNotEmpty) ? item.notas! : '-',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────── Helpers ───────────────────────────────────────
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

  Widget _campo(String label, String? valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),
            ),
          ),
          Expanded(child: Text(valor?.isNotEmpty == true ? valor! : '-', style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
