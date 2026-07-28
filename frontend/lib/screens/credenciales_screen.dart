import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:credenciales_web/classes/credenciales_consulta.dart';
import 'package:credenciales_web/classes/credencial.dart';
import 'package:credenciales_web/screens/credencial_editar_screen.dart';
import 'package:credenciales_web/db/categoria_access.dart';
import 'package:credenciales_web/db/database_access.dart';

class CredencialesScreen extends StatefulWidget {
  final int rolId;

  const CredencialesScreen({super.key, this.rolId = 0});

  @override
  State<CredencialesScreen> createState() => _CredencialesScreenState();
}

class _CredencialesScreenState extends State<CredencialesScreen> {
  bool _loading = false;
  List<CredencialesConsulta> _credenciales = [];
  String? _filtroDescripcion;
  String? _filtroUsuario;
  String? _filtroNotas;
  int? _filtroCategoria;

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
      // Pedimos al backend la búsqueda por `descripcion`, `usuario` y `notas`.
      // `notas` se trata como texto normal y el filtrado lo aplica el backend.
      // Debug: mostrar filtros usados
      // ignore: avoid_print
      print(
        'Cargar credenciales con filtros: descripcion=$_filtroDescripcion usuario=$_filtroUsuario notas=$_filtroNotas categoria=$_filtroCategoria',
      );
      final credenciales = await CredencialesConsulta.lista(
        descripcion: _filtroDescripcion,
        usuario: _filtroUsuario,
        notas: _filtroNotas,
        categoriaId: _filtroCategoria,
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
    final values = [_filtroDescripcion, _filtroUsuario, _filtroNotas];
    for (final value in values) {
      if (value == null) continue;
      if (value.trim().isEmpty) continue;
      count++;
    }
    if (_filtroCategoria != null) count++;
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

  Future<void> _abrirFiltros() async {
    final filtros = await showDialog<_CredencialesFiltrosResultado?>(
      context: context,
      builder: (context) => _CredencialesFiltrosDialog(
        descripcion: _filtroDescripcion,
        usuario: _filtroUsuario,
        notas: _filtroNotas,
        categoriaId: _filtroCategoria,
        textoONull: _textoONull,
      ),
    );

    if (filtros == null || !mounted) {
      return;
    }

    if (filtros.limpiar) {
      setState(() {
        _filtroDescripcion = null;
        _filtroUsuario = null;
        _filtroNotas = null;
        _filtroCategoria = null;
      });
      await _cargarCredenciales();
      return;
    }

    setState(() {
      _filtroDescripcion = filtros.descripcion;
      _filtroUsuario = filtros.usuario;
      _filtroNotas = filtros.notas;
      _filtroCategoria = filtros.categoriaId;
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
                                              DataColumn(label: Text('Descripción')),
                                              DataColumn(label: Text('Categoría')),
                                              DataColumn(label: Text('Usuario')),
                                              DataColumn(label: Text('Password')),
                                              DataColumn(label: Text('Notas')),
                                              DataColumn(label: Text('Acciones')),
                                            ],
                                            rows: _credenciales.map((credencial) {
                                              return DataRow(
                                                cells: [
                                                  DataCell(Text(credencial.descripcion ?? '')),
                                                  DataCell(Text(credencial.categoriaNombre ?? '')),
                                                  DataCell(Text(credencial.usuario ?? '')),
                                                  DataCell(
                                                    Builder(
                                                      builder: (context) {
                                                        final pwd = credencial.password ?? '';
                                                        final obscure = ValueNotifier<bool>(true);
                                                        String masked() =>
                                                            pwd.isEmpty ? '' : List.filled(pwd.length, '•').join();
                                                        return ValueListenableBuilder<bool>(
                                                          valueListenable: obscure,
                                                          builder: (context, isObscure, _) {
                                                            return Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Flexible(child: Text(isObscure ? masked() : pwd)),
                                                                IconButton(
                                                                  tooltip: 'Copiar password',
                                                                  icon: const Icon(Icons.copy, size: 18),
                                                                  onPressed: () {
                                                                    if (pwd.isEmpty) {
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        const SnackBar(
                                                                          content: Text('No hay password para copiar'),
                                                                        ),
                                                                      );
                                                                      return;
                                                                    }
                                                                    Clipboard.setData(ClipboardData(text: pwd));
                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                      const SnackBar(
                                                                        content: Text(
                                                                          'Password copiado al portapapeles',
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                                IconButton(
                                                                  tooltip: isObscure
                                                                      ? 'Mostrar password'
                                                                      : 'Ocultar password',
                                                                  icon: Icon(
                                                                    isObscure ? Icons.visibility : Icons.visibility_off,
                                                                    size: 18,
                                                                  ),
                                                                  onPressed: () => obscure.value = !obscure.value,
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  DataCell(Text(credencial.notas ?? '')),
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
                                                        if (widget.rolId == 1)
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
  final String? descripcion;
  final String? usuario;
  final String? notas;
  final int? categoriaId;
  const _CredencialesFiltrosResultado({
    this.limpiar = false,
    this.descripcion,
    this.usuario,
    this.notas,
    this.categoriaId,
  });
}

class _CredencialesFiltrosDialog extends StatefulWidget {
  const _CredencialesFiltrosDialog({
    required this.descripcion,
    required this.usuario,
    required this.notas,
    required this.categoriaId,
    required this.textoONull,
  });

  final String? descripcion;
  final String? usuario;
  final String? notas;
  final int? categoriaId;
  final String? Function(String text) textoONull;

  @override
  State<_CredencialesFiltrosDialog> createState() => _CredencialesFiltrosDialogState();
}

class _CredencialesFiltrosDialogState extends State<_CredencialesFiltrosDialog> {
  late final TextEditingController descripcionController;
  late final TextEditingController usuarioController;
  late final TextEditingController notasController;
  List<Map<String, dynamic>> _categorias = [];
  int? _selectedCategoria;
  bool _categoriasLoaded = false;

  @override
  void initState() {
    super.initState();
    descripcionController = TextEditingController(text: widget.descripcion ?? '');
    usuarioController = TextEditingController(text: widget.usuario ?? '');
    notasController = TextEditingController(text: widget.notas ?? '');
    _selectedCategoria = widget.categoriaId;
    _loadCategorias();
  }

  @override
  void dispose() {
    descripcionController.dispose();
    usuarioController.dispose();
    notasController.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias() async {
    try {
      final db = DatabaseAccess();
      final catAccess = CategoriaAccess(databaseAccess: db);
      final lista = await catAccess.listaCategoriaApi();
      if (!mounted) return;
      setState(() {
        _categorias = lista;
        _categoriasLoaded = true;
      });
    } catch (_) {
      // ignorar errores y dejar lista vacía
      if (!mounted) return;
      setState(() {
        _categorias = [];
        _categoriasLoaded = true;
      });
    }
  }

  void _aplicar() {
    // Debug: mostrar selección antes de cerrar
    // ignore: avoid_print
    print(
      'Filtros: aplicar descripcion=${widget.textoONull(descripcionController.text)} usuario=${widget.textoONull(usuarioController.text)} notas=${widget.textoONull(notasController.text)} categoriaId=$_selectedCategoria',
    );
    Navigator.of(context).pop(
      _CredencialesFiltrosResultado(
        descripcion: widget.textoONull(descripcionController.text),
        usuario: widget.textoONull(usuarioController.text),
        notas: widget.textoONull(notasController.text),
        categoriaId: _selectedCategoria,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtros de credenciales'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Builder(
                  builder: (context) {
                    // Construir mapa deduplicado de categorías por id
                    final Map<int, String> catMap = {};
                    for (final c in _categorias) {
                      try {
                        final id = c['id'] is int ? c['id'] as int : int.parse(c['id'].toString());
                        final nombre = c['nombre']?.toString() ?? '';
                        if (!catMap.containsKey(id)) catMap[id] = nombre;
                      } catch (_) {
                        // ignorar entradas malformadas
                      }
                    }

                    // Si la seleccion actual no existe en el mapa, anularla solo si
                    // ya cargamos las categorias (evita limpiar prematuramente).
                    if (_selectedCategoria != null && _categoriasLoaded && !catMap.containsKey(_selectedCategoria)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _selectedCategoria = null);
                      });
                    }

                    final items = <DropdownMenuItem<int?>>[
                      const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
                      ...catMap.entries.map((e) => DropdownMenuItem<int?>(value: e.key, child: Text(e.value))),
                    ];

                    // Debug: imprimir keys/values e item values
                    // ignore: avoid_print
                    print(
                      'DEBUG Dropdown: catKeys=${catMap.keys.toList()} items=${items.map((i) => i.value).toList()} selected=$_selectedCategoria loaded=$_categoriasLoaded',
                    );

                    // Filtrar duplicados por value para evitar assertion de Dropdown
                    final seen = <int?>{};
                    final uniqueItems = <DropdownMenuItem<int?>>[];
                    for (final it in items) {
                      final v = it.value;
                      if (seen.contains(v)) continue;
                      seen.add(v);
                      uniqueItems.add(it);
                    }

                    // Asegurar que el `value` exista entre los items; si no, usar null
                    final hasSelected = uniqueItems.any((it) => it.value == _selectedCategoria);
                    final valueForDropdown = (_categoriasLoaded && hasSelected) ? _selectedCategoria : null;

                    return DropdownButtonFormField<int?>(
                      initialValue: valueForDropdown,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: uniqueItems,
                      onChanged: (v) => setState(() => _selectedCategoria = v),
                    );
                  },
                ),
              ),
              TextField(
                controller: descripcionController,
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                decoration: const InputDecoration(labelText: 'Descripción (contiene)'),
              ),
              TextField(
                controller: usuarioController,
                inputFormatters: [LengthLimitingTextInputFormatter(80)],
                decoration: const InputDecoration(labelText: 'Usuario (contiene)'),
              ),
              TextField(
                controller: notasController,
                inputFormatters: [LengthLimitingTextInputFormatter(200)],
                decoration: const InputDecoration(labelText: 'Notas (contiene)'),
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
