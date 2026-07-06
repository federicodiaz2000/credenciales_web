import 'package:flutter/material.dart';
import 'package:credenciales_web/classes/rol.dart';
import 'package:credenciales_web/classes/usuario.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  bool _loading = false;
  List<Usuario> _usuarios = [];
  List<Rol> _roles = [];

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
      final usuarios = await Usuario.lista();
      final roles = await Rol.lista();

      if (!mounted) return;
      setState(() {
        _usuarios = usuarios;
        _roles = roles;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar usuarios: $e')));
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  String _nombreRol(int rolId) {
    for (final rol in _roles) {
      if (rol.id == rolId) {
        return rol.nombre;
      }
    }
    return 'Rol $rolId';
  }

  Future<void> _abrirDialogoUsuario({Usuario? usuario}) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => _UsuarioDialog(usuario: usuario, roles: _roles),
    );

    if (resultado == true) {
      await _cargarDatos();
    }
  }

  Future<void> _eliminarUsuario(Usuario usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Eliminar al usuario "${usuario.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmar != true) {
      return;
    }

    try {
      await Usuario.eliminar(id: usuario.id);
      await _cargarDatos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar usuario: $e')));
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
                  child: Text('Gestión de usuarios', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: 'Recargar',
                  onPressed: _loading ? null : _cargarDatos,
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: (_loading || _roles.isEmpty) ? null : () => _abrirDialogoUsuario(),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar usuario'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading && _usuarios.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _usuarios.isEmpty
                ? const Center(child: Text('No hay usuarios cargados.'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Rol')),
                          DataColumn(label: Text('Activo')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: _usuarios.map((usuario) {
                          final rolId = usuario.rolId;
                          final activo = usuario.activo;
                          return DataRow(
                            cells: [
                              DataCell(Text('${usuario.id}')),
                              DataCell(Text(usuario.nombre)),
                              DataCell(Text(usuario.email)),
                              DataCell(Text(_nombreRol(rolId))),
                              DataCell(Text(activo ? 'Sí' : 'No')),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Modificar',
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: _loading ? null : () => _abrirDialogoUsuario(usuario: usuario),
                                    ),
                                    IconButton(
                                      tooltip: 'Eliminar',
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: _loading ? null : () => _eliminarUsuario(usuario),
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

class _UsuarioDialog extends StatefulWidget {
  final Usuario? usuario;
  final List<Rol> roles;

  const _UsuarioDialog({required this.usuario, required this.roles});

  @override
  State<_UsuarioDialog> createState() => _UsuarioDialogState();
}

class _UsuarioDialogState extends State<_UsuarioDialog> {
  late final TextEditingController _nombreController;
  late final TextEditingController _emailController;
  late int? _rolSeleccionado;
  late bool _activo;
  bool _guardando = false;

  bool get _esEdicion => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.usuario?.nombre ?? '');
    _emailController = TextEditingController(text: widget.usuario?.email ?? '');
    _rolSeleccionado = widget.usuario?.rolId ?? (widget.roles.isNotEmpty ? widget.roles.first.id : null);
    _activo = widget.usuario?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    final email = _emailController.text.trim();

    if (nombre.isEmpty || email.isEmpty || _rolSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa nombre, email y rol.')));
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      if (_esEdicion) {
        await Usuario.actualizar(
          id: widget.usuario!.id,
          nombre: nombre,
          email: email,
          rolId: _rolSeleccionado!,
          activo: _activo,
        );
      } else {
        await Usuario.agregar(nombre: nombre, email: email, rolId: _rolSeleccionado!, activo: _activo);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar usuario: $e')));
      setState(() {
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_esEdicion ? 'Modificar usuario' : 'Agregar usuario'),
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
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _rolSeleccionado,
                items: widget.roles
                    .map((rol) => DropdownMenuItem<int>(value: rol.id, child: Text('${rol.id} - ${rol.nombre}')))
                    .toList(),
                onChanged: _guardando
                    ? null
                    : (value) {
                        setState(() {
                          _rolSeleccionado = value;
                        });
                      },
                decoration: const InputDecoration(labelText: 'Rol'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activo'),
                value: _activo,
                onChanged: _guardando
                    ? null
                    : (value) {
                        setState(() {
                          _activo = value;
                        });
                      },
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
