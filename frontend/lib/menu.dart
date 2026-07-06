// Hamburger Menu básico con Scaffold
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:credenciales_web/classes/usuario.dart';
import 'package:credenciales_web/config/colores.dart';
import 'package:credenciales_web/screens/credenciales_screen.dart';
import 'package:credenciales_web/screens/acerca_de_screen.dart';
import 'package:credenciales_web/screens/inicio_screen.dart';
import 'package:credenciales_web/screens/usuarios_screen.dart';

class MenuPrincipal extends StatefulWidget {
  final int usuarioId;
  final String usuarioNombre;
  final int rolId;
  final Future<void> Function() onCerrarSesion;

  static const int menuInicio = 0;
  static const int menuActualizarCredenciales = 1;
  static const int menuConfiguracion = 2;
  static const int menuUsuarios = 3;
  static const int menuAcercaDe = 4;

  const MenuPrincipal({
    super.key,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.rolId,
    required this.onCerrarSesion,
  });

  @override
  State<MenuPrincipal> createState() => _MenuPrincipalState();
}

class _MenuPrincipalState extends State<MenuPrincipal> with WidgetsBindingObserver {
  int _selectedMenuOption = MenuPrincipal.menuInicio;
  Usuario? _usuarioActivo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarUsuarioActivo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _cargarUsuarioActivo() async {
    final usuario = await Usuario.obtenerPorId(widget.usuarioId);
    if (!mounted) return;
    setState(() {
      _usuarioActivo = usuario;
    });
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar la sesión actual?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Cerrar sesión')),
        ],
      ),
    );

    if (confirmar == true) {
      await widget.onCerrarSesion();
    }
  }

  String get _nombreRol {
    if (widget.rolId == 1) {
      return 'Administrador';
    }
    if (widget.rolId == 2) {
      return 'Usuario';
    }
    if (widget.rolId == 3) {
      return 'Usuario Externo';
    }
    return 'Rol ${widget.rolId}';
  }

  bool get _esRolUsuario => widget.rolId == 2;

  Future<void> _seleccionarMenu(BuildContext drawerContext, int opcion) async {
    Navigator.of(drawerContext).pop();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() {
      _selectedMenuOption = opcion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  _tituloVentana(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 20, // Título más grande
                  ),
                ),
              ),
            ),
            SizedBox(width: 24),
            Icon(_iconoVentana(), color: Colors.blue),
          ],
        ),
        backgroundColor: Colores.titleBackground,
        foregroundColor: Colors.white,
      ),
      // El Drawer se muestra automáticamente como hamburger menu
      drawer: Drawer(
        child: Builder(
          builder: (drawerContext) => ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header del drawer
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color.fromARGB(255, 4, 63, 112), Colores.titleBackground],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),

                // Encabezado del Menu
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset("assets/images/credencial.svg", height: 110, alignment: Alignment.centerLeft),
                      //Image.asset("assets/images/marcas/020000601.bmp", height: 110, alignment: Alignment.centerLeft),
                      Text('Credenciales', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text('Usuario ID: ${widget.usuarioId}', style: TextStyle(color: Colors.white, fontSize: 15)),
                    ],
                  ),
                ),
              ),

              // Opciones del menú -> Inicio
              ListTile(
                leading: Icon(Icons.home),
                title: Text('Inicio', style: TextStyle(fontSize: 14)),
                onTap: () => _seleccionarMenu(drawerContext, MenuPrincipal.menuInicio),
              ),

              ListTile(
                leading: Icon(Icons.update),
                title: Text('Credenciales', style: TextStyle(fontSize: 14)),
                onTap: () => _seleccionarMenu(drawerContext, MenuPrincipal.menuActualizarCredenciales),
              ),

              if (!_esRolUsuario)
                ListTile(
                  leading: Icon(Icons.people),
                  title: Text('Usuarios', style: TextStyle(fontSize: 14)),
                  onTap: () => _seleccionarMenu(drawerContext, MenuPrincipal.menuUsuarios),
                ),

              if (!_esRolUsuario)
                // Configuración
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Configuración', style: TextStyle(fontSize: 14)),
                  onTap: () => _seleccionarMenu(drawerContext, MenuPrincipal.menuConfiguracion),
                ),

              Divider(),

              ListTile(
                leading: Icon(Icons.info),
                title: Text('Acerca de', style: TextStyle(fontSize: 14)),
                onTap: () => _seleccionarMenu(drawerContext, MenuPrincipal.menuAcercaDe),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Usuario activo',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ),
                    IconButton(tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout), onPressed: _cerrarSesion),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usuario: ${_usuarioActivo?.nombre ?? widget.usuarioNombre}',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text('Rol: $_nombreRol', style: TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_selectedMenuOption) {
      case MenuPrincipal.menuInicio:
        return InicioScreen();

      case MenuPrincipal.menuActualizarCredenciales:
        return CredencialesScreen(rolId: widget.rolId);

      case MenuPrincipal.menuConfiguracion:
        // TODO: Reemplazar con pantalla real de configuración. Por ahora se muestra Inicio
        return InicioScreen();

      case MenuPrincipal.menuUsuarios:
        return UsuariosScreen();

      case MenuPrincipal.menuAcercaDe:
        return AcercaDeScreen();

      default:
        return InicioScreen();
    }
  }

  String _tituloVentana() {
    switch (_selectedMenuOption) {
      case MenuPrincipal.menuInicio:
        return "Inicio";
      case MenuPrincipal.menuActualizarCredenciales:
        return "Actualizar Credenciales";
      case MenuPrincipal.menuConfiguracion:
        return "Configuración";
      case MenuPrincipal.menuUsuarios:
        return "Usuarios";
      case MenuPrincipal.menuAcercaDe:
        return "Acerca de";
      default:
        return "Inicio";
    }
  }

  IconData _iconoVentana() {
    switch (_selectedMenuOption) {
      case MenuPrincipal.menuInicio:
        return Icons.home;

      case MenuPrincipal.menuActualizarCredenciales:
        return Icons.update;

      case MenuPrincipal.menuConfiguracion:
        return Icons.settings;

      case MenuPrincipal.menuUsuarios:
        return Icons.people;

      case MenuPrincipal.menuAcercaDe:
        return Icons.info;
      default:
        return Icons.home;
    }
  }
}
