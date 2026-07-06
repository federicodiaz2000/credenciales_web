import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:credenciales_web/classes/credenciales_consulta.dart';
import 'package:credenciales_web/classes/credencial.dart';
import 'package:credenciales_web/screens/credencial_editar_screen.dart';

class CredencialesScreen extends StatefulWidget {
  const CredencialesScreen({super.key});

  @override
  State<CredencialesScreen> createState() => _CredencialesScreenState();
}

class _CredencialesScreenState extends State<CredencialesScreen> {
  bool _loading = false;
  List<CredencialesConsulta> _credenciales = [];

  int? _filtroCredencialId;
  String? _filtroRenspa;
  String? _filtroSenialDescripcion;
  String? _filtroExpediente;
  String? _filtroOficinaCargaCodigo;
  int? _filtroOficinaTransaccion;
  int? _filtroTitularNumeroDocumento;
  int? _filtroEstablecimientoCuit;
  String? _filtroTitularDescripcion;
  String? _filtroTitularTelefono;
  String? _filtroTitularDomicilio;
  String? _filtroEstablecimientoDescripcion;

  @override
  void initState() {
    super.initState();
    _cargarCredenciales();
  }

  Future<bool> _confirmDelete(BuildContext context, int? credencialId) async {
    if (credencialId == null) return false;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Desea eliminar la credencial $credencialId?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    return confirmar == true;
  }

  Future<void> _cargarCredenciales() async {
    setState(() {
      _loading = true;
    });

    try {
      final credenciales = await CredencialesConsulta.lista(
        credencialId: _filtroCredencialId,
        renspa: _filtroRenspa,
        senialDescripcion: _filtroSenialDescripcion,
        expediente: _filtroExpediente,
        oficinaCargaCodigo: _filtroOficinaCargaCodigo,
        oficinaTransaccion: _filtroOficinaTransaccion,
        titularNumeroDocumento: _filtroTitularNumeroDocumento,
        establecimientoCuit: _filtroEstablecimientoCuit,
        titularDescripcion: _filtroTitularDescripcion,
        titularTelefono: _filtroTitularTelefono,
        titularDomicilio: _filtroTitularDomicilio,
        establecimientoDescripcion: _filtroEstablecimientoDescripcion,
      );
      if (!mounted) return;
      setState(() {
        _credenciales = credenciales;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar credenciales: $e')));
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  int get _cantidadFiltrosActivos {
    var count = 0;
    final values = [
      _filtroCredencialId,
      _filtroRenspa,
      _filtroSenialDescripcion,
      _filtroExpediente,
      _filtroOficinaCargaCodigo,
      _filtroOficinaTransaccion,
      _filtroTitularNumeroDocumento,
      _filtroEstablecimientoCuit,
      _filtroTitularDescripcion,
      _filtroTitularTelefono,
      _filtroTitularDomicilio,
      _filtroEstablecimientoDescripcion,
    ];

    for (final value in values) {
      if (value == null) {
        continue;
      }
      if (value is String && value.trim().isEmpty) {
        continue;
      }
      count++;
    }
    return count;
  }

  String get _textoCantidadFiltros {
    if (_cantidadFiltrosActivos == 1) {
      return '1 filtro';
    }
    return '$_cantidadFiltrosActivos filtros';
  }

  String? _textoONull(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int? _intONull(String text, String nombreCampo) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final value = int.tryParse(trimmed);
    if (value == null) {
      throw FormatException('El campo "$nombreCampo" debe ser numérico.');
    }
    return value;
  }

  Future<void> _abrirFiltros() async {
    final filtros = await showDialog<_CredencialesFiltrosResultado?>(
      context: context,
      builder: (context) => _CredencialesFiltrosDialog(
        credencialId: _filtroCredencialId,
        renspa: _filtroRenspa,
        senialDescripcion: _filtroSenialDescripcion,
        expediente: _filtroExpediente,
        oficinaCargaCodigo: _filtroOficinaCargaCodigo,
        oficinaTransaccion: _filtroOficinaTransaccion,
        titularNumeroDocumento: _filtroTitularNumeroDocumento,
        establecimientoCuit: _filtroEstablecimientoCuit,
        titularDescripcion: _filtroTitularDescripcion,
        titularTelefono: _filtroTitularTelefono,
        titularDomicilio: _filtroTitularDomicilio,
        establecimientoDescripcion: _filtroEstablecimientoDescripcion,
        intONull: _intONull,
        textoONull: _textoONull,
      ),
    );

    if (filtros == null || !mounted) {
      return;
    }

    if (filtros.limpiar) {
      setState(() {
        _filtroCredencialId = null;
        _filtroRenspa = null;
        _filtroSenialDescripcion = null;
        _filtroExpediente = null;
        _filtroOficinaCargaCodigo = null;
        _filtroOficinaTransaccion = null;
        _filtroTitularNumeroDocumento = null;
        _filtroEstablecimientoCuit = null;
        _filtroTitularDescripcion = null;
        _filtroTitularTelefono = null;
        _filtroTitularDomicilio = null;
        _filtroEstablecimientoDescripcion = null;
      });
      await _cargarCredenciales();
      return;
    }

    setState(() {
      _filtroCredencialId = filtros.credencialId;
      _filtroRenspa = filtros.renspa;
      _filtroSenialDescripcion = filtros.senialDescripcion;
      _filtroExpediente = filtros.expediente;
      _filtroOficinaCargaCodigo = filtros.oficinaCargaCodigo;
      _filtroOficinaTransaccion = filtros.oficinaTransaccion;
      _filtroTitularNumeroDocumento = filtros.titularNumeroDocumento;
      _filtroEstablecimientoCuit = filtros.establecimientoCuit;
      _filtroTitularDescripcion = filtros.titularDescripcion;
      _filtroTitularTelefono = filtros.titularTelefono;
      _filtroTitularDomicilio = filtros.titularDomicilio;
      _filtroEstablecimientoDescripcion = filtros.establecimientoDescripcion;
    });
    await _cargarCredenciales();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: const Color(0xFFF6F9FF),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Actualizar credenciales${_cantidadFiltrosActivos > 0 ? ' ($_textoCantidadFiltros)' : ''}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final resultado = await Navigator.push<bool?>(
                          context,
                          MaterialPageRoute(builder: (_) => CredencialEditarScreen(credencialId: null)),
                        );
                        if (resultado == true && mounted) await _cargarCredenciales();
                      },
                      icon: const Icon(Icons.add),
                      label: const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Recargar',
                      onPressed: _loading ? null : _cargarCredenciales,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading && _credenciales.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _credenciales.isEmpty
                    ? const Center(child: Text('No hay credenciales cargadas.'))
                    : OrientationBuilder(
                        builder: (context, orientation) {
                          final isLandscape = orientation == Orientation.landscape;

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                        child: SingleChildScrollView(
                                          padding: const EdgeInsets.only(bottom: 80),
                                          child: DataTable(
                                            dataRowMinHeight: isLandscape ? 54 : 46,
                                            dataRowMaxHeight: isLandscape ? 60 : 52,
                                            headingRowHeight: 42,
                                            columns: const [
                                              DataColumn(label: Text('Acciones')),
                                              DataColumn(label: Text('Código')),
                                              DataColumn(label: Text('Descripción')),
                                              DataColumn(label: Text('Usuario')),
                                              DataColumn(label: Text('Notas')),
                                            ],
                                            rows: _credenciales.map((credencial) {
                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          tooltip: 'Editar',
                                                          icon: const Icon(Icons.edit),
                                                          onPressed: () async {
                                                            final resultado = await Navigator.of(context).push<bool>(
                                                              MaterialPageRoute(
                                                                builder: (_) => CredencialEditarScreen(
                                                                  credencialId: credencial.credencialId,
                                                                ),
                                                              ),
                                                            );
                                                            if (resultado == true && mounted) {
                                                              await _cargarCredenciales();
                                                            }
                                                          },
                                                        ),
                                                        IconButton(
                                                          tooltip: 'Eliminar',
                                                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                                                          onPressed: () async {
                                                            final confirmed = await _confirmDelete(
                                                              context,
                                                              credencial.credencialId,
                                                            );
                                                            if (!confirmed) return;
                                                            if (!mounted) return;
                                                            setState(() {
                                                              _loading = true;
                                                            });
                                                            try {
                                                              await Credencial.eliminar(credencial.credencialId!);
                                                              if (!mounted) return;
                                                              // ignore: use_build_context_synchronously
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Credencial ${credencial.credencialId} eliminado',
                                                                  ),
                                                                ),
                                                              );
                                                              await _cargarCredenciales();
                                                            } catch (e) {
                                                              if (!mounted) return;
                                                              // ignore: use_build_context_synchronously
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: Text('Error al eliminar credencial: $e'),
                                                                ),
                                                              );
                                                            } finally {
                                                              // ignore: control_flow_in_finally
                                                              if (!mounted) return;
                                                              setState(() {
                                                                _loading = false;
                                                              });
                                                            }
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  DataCell(Text('${credencial.credencialId}')),
                                                  DataCell(Text(credencial.descripcion ?? '')),
                                                  DataCell(Text(credencial.usuario ?? '')),
                                                  DataCell(Text(credencial.notas ?? '')),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'credenciales-filtros-fab',
            onPressed: _abrirFiltros,
            icon: const Icon(Icons.tune),
            label: Text(_cantidadFiltrosActivos > 0 ? 'Filtros ($_textoCantidadFiltros)' : 'Filtros'),
          ),
        ),
      ],
    );
  }
}

class _CredencialesFiltrosResultado {
  final bool limpiar;
  final int? credencialId;
  final String? renspa;
  final String? senialDescripcion;
  final String? expediente;
  final String? oficinaCargaCodigo;
  final int? oficinaTransaccion;
  final int? titularNumeroDocumento;
  final int? establecimientoCuit;
  final String? titularDescripcion;
  final String? titularTelefono;
  final String? titularDomicilio;
  final String? establecimientoDescripcion;

  const _CredencialesFiltrosResultado({
    this.limpiar = false,
    this.credencialId,
    this.renspa,
    this.senialDescripcion,
    this.expediente,
    this.oficinaCargaCodigo,
    this.oficinaTransaccion,
    this.titularNumeroDocumento,
    this.establecimientoCuit,
    this.titularDescripcion,
    this.titularTelefono,
    this.titularDomicilio,
    this.establecimientoDescripcion,
  });
}

class _CredencialesFiltrosDialog extends StatefulWidget {
  const _CredencialesFiltrosDialog({
    required this.credencialId,
    required this.renspa,
    required this.senialDescripcion,
    required this.expediente,
    required this.oficinaCargaCodigo,
    required this.oficinaTransaccion,
    required this.titularNumeroDocumento,
    required this.establecimientoCuit,
    required this.titularDescripcion,
    required this.titularTelefono,
    required this.titularDomicilio,
    required this.establecimientoDescripcion,
    required this.intONull,
    required this.textoONull,
  });

  final int? credencialId;
  final String? renspa;
  final String? senialDescripcion;
  final String? expediente;
  final String? oficinaCargaCodigo;
  final int? oficinaTransaccion;
  final int? titularNumeroDocumento;
  final int? establecimientoCuit;
  final String? titularDescripcion;
  final String? titularTelefono;
  final String? titularDomicilio;
  final String? establecimientoDescripcion;
  final int? Function(String text, String nombreCampo) intONull;
  final String? Function(String text) textoONull;

  @override
  State<_CredencialesFiltrosDialog> createState() => _CredencialesFiltrosDialogState();
}

class _CredencialesFiltrosDialogState extends State<_CredencialesFiltrosDialog> {
  late final TextEditingController credencialIdController;
  late final TextEditingController renspaController;
  late final TextEditingController senialDescripcionController;
  late final TextEditingController expedienteController;
  late final TextEditingController oficinaCargaCodigoController;
  late final TextEditingController oficinaTransaccionController;
  late final TextEditingController titularNumeroDocumentoController;
  late final TextEditingController establecimientoCuitController;
  late final TextEditingController titularDescripcionController;
  late final TextEditingController titularTelefonoController;
  late final TextEditingController titularDomicilioController;
  late final TextEditingController establecimientoDescripcionController;

  @override
  void initState() {
    super.initState();
    credencialIdController = TextEditingController(text: widget.credencialId?.toString() ?? '');
    renspaController = TextEditingController(text: widget.renspa ?? '');
    senialDescripcionController = TextEditingController(text: widget.senialDescripcion ?? '');
    expedienteController = TextEditingController(text: widget.expediente ?? '');
    oficinaCargaCodigoController = TextEditingController(text: widget.oficinaCargaCodigo ?? '');
    oficinaTransaccionController = TextEditingController(text: widget.oficinaTransaccion?.toString() ?? '');
    titularNumeroDocumentoController = TextEditingController(text: widget.titularNumeroDocumento?.toString() ?? '');
    establecimientoCuitController = TextEditingController(text: widget.establecimientoCuit?.toString() ?? '');
    titularDescripcionController = TextEditingController(text: widget.titularDescripcion ?? '');
    titularTelefonoController = TextEditingController(text: widget.titularTelefono ?? '');
    titularDomicilioController = TextEditingController(text: widget.titularDomicilio ?? '');
    establecimientoDescripcionController = TextEditingController(text: widget.establecimientoDescripcion ?? '');
  }

  @override
  void dispose() {
    credencialIdController.dispose();
    renspaController.dispose();
    senialDescripcionController.dispose();
    expedienteController.dispose();
    oficinaCargaCodigoController.dispose();
    oficinaTransaccionController.dispose();
    titularNumeroDocumentoController.dispose();
    establecimientoCuitController.dispose();
    titularDescripcionController.dispose();
    titularTelefonoController.dispose();
    titularDomicilioController.dispose();
    establecimientoDescripcionController.dispose();
    super.dispose();
  }

  void _aplicar() {
    try {
      Navigator.of(context).pop(
        _CredencialesFiltrosResultado(
          credencialId: widget.intONull(credencialIdController.text, 'Credencial código'),
          renspa: widget.textoONull(renspaController.text),
          senialDescripcion: widget.textoONull(senialDescripcionController.text),
          expediente: widget.textoONull(expedienteController.text),
          oficinaCargaCodigo: widget.textoONull(oficinaCargaCodigoController.text),
          oficinaTransaccion: widget.intONull(oficinaTransaccionController.text, 'Oficina transacción'),
          titularNumeroDocumento: widget.intONull(titularNumeroDocumentoController.text, 'Titular número documento'),
          establecimientoCuit: widget.intONull(establecimientoCuitController.text, 'CUIT establecimiento'),
          titularDescripcion: widget.textoONull(titularDescripcionController.text),
          titularTelefono: widget.textoONull(titularTelefonoController.text),
          titularDomicilio: widget.textoONull(titularDomicilioController.text),
          establecimientoDescripcion: widget.textoONull(establecimientoDescripcionController.text),
        ),
      );
    } on FormatException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtros de credenciales'),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: credencialIdController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                decoration: const InputDecoration(labelText: 'Credencial código (exacto)'),
              ),
              TextField(
                controller: renspaController,
                inputFormatters: [LengthLimitingTextInputFormatter(16)],
                decoration: const InputDecoration(labelText: 'Renspa (contiene)'),
              ),
              TextField(
                controller: senialDescripcionController,
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
                decoration: const InputDecoration(labelText: 'Señal descripción (contiene)'),
              ),
              TextField(
                controller: expedienteController,
                inputFormatters: [LengthLimitingTextInputFormatter(16)],
                decoration: const InputDecoration(labelText: 'Expediente (contiene)'),
              ),
              TextField(
                controller: oficinaCargaCodigoController,
                inputFormatters: [LengthLimitingTextInputFormatter(3)],
                decoration: const InputDecoration(labelText: 'Oficina carga código (contiene)'),
              ),
              TextField(
                controller: oficinaTransaccionController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                decoration: const InputDecoration(labelText: 'Oficina transacción (exacto)'),
              ),
              TextField(
                controller: titularNumeroDocumentoController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                decoration: const InputDecoration(labelText: 'Titular Documento (exacto)'),
              ),
              TextField(
                controller: titularDescripcionController,
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
                decoration: const InputDecoration(labelText: 'Titular (contiene)'),
              ),
              TextField(
                controller: titularTelefonoController,
                inputFormatters: [LengthLimitingTextInputFormatter(20)],
                decoration: const InputDecoration(labelText: 'Titular teléfono (contiene)'),
              ),
              TextField(
                controller: titularDomicilioController,
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
                decoration: const InputDecoration(labelText: 'Titular domicilio (contiene)'),
              ),

              TextField(
                controller: establecimientoCuitController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                decoration: const InputDecoration(labelText: 'CUIT establecimiento (exacto, max 11)'),
              ),
              TextField(
                controller: establecimientoDescripcionController,
                inputFormatters: [LengthLimitingTextInputFormatter(50)],
                decoration: const InputDecoration(labelText: 'Establecimiento (contiene)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(const _CredencialesFiltrosResultado(limpiar: true)),
          child: const Text('Limpiar'),
        ),
        ElevatedButton(onPressed: _aplicar, child: const Text('Aplicar')),
      ],
    );
  }
}
