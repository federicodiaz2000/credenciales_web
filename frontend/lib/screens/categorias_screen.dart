import 'package:flutter/material.dart';
import 'package:credenciales_web/classes/categoria.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  bool _loading = false;
  List<Categoria> _categorias = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _loading = true;
    });

    try {
      final categorias = await Categoria.lista();
      if (!mounted) return;
      setState(() {
        _categorias = categorias;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar categorías: $e')));
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _abrirDialogoCategoria({Categoria? categoria}) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => _CategoriaDialog(categoria: categoria),
    );

    if (resultado == true) {
      await _cargarDatos();
    }
  }

  Future<void> _eliminarCategoria(Categoria categoria) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar la categoría "${categoria.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await Categoria.eliminar(id: categoria.id);
      await _cargarDatos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar categoría: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F9FF),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Gestión de categorías', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: 'Recargar',
                  onPressed: _loading ? null : _cargarDatos,
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loading ? null : () => _abrirDialogoCategoria(),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar categoría'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading && _categorias.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _categorias.isEmpty
                ? const Center(child: Text('No hay categorías cargadas.'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: _categorias.map((categoria) {
                          return DataRow(
                            cells: [
                              DataCell(Text('${categoria.id}')),
                              DataCell(Text(categoria.nombre)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Modificar',
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: _loading ? null : () => _abrirDialogoCategoria(categoria: categoria),
                                    ),
                                    IconButton(
                                      tooltip: 'Eliminar',
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: _loading ? null : () => _eliminarCategoria(categoria),
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
        ],
      ),
    );
  }
}

class _CategoriaDialog extends StatefulWidget {
  final Categoria? categoria;

  const _CategoriaDialog({required this.categoria});

  @override
  State<_CategoriaDialog> createState() => _CategoriaDialogState();
}

class _CategoriaDialogState extends State<_CategoriaDialog> {
  late final TextEditingController _nombreController;
  bool _guardando = false;

  bool get _esEdicion => widget.categoria != null;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.categoria?.nombre ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa el nombre.')));
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      if (_esEdicion) {
        await Categoria.actualizar(id: widget.categoria!.id, nombre: nombre);
      } else {
        await Categoria.agregar(nombre: nombre);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar categoría: $e')));
      setState(() {
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esEdicion ? 'Modificar categoría' : 'Agregar categoría'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _guardando ? null : _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
