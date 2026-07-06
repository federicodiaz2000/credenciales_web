import 'package:flutter/material.dart';
import 'package:credenciales_web/menu.dart';
import 'package:credenciales_web/screens/login_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'db/database_access.dart';
import 'db/usuario_login_access.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _cargandoConfiguracion = true;
  bool _usuarioLogueado = false;
  int _usuarioId = 0;
  int _usuarioRolId = 0;
  String _usuarioNombre = '';
  String _loginId = '';

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    await DatabaseAccess.crearBaseDeDatos();
    if (!mounted) return;
    setState(() {
      _cargandoConfiguracion = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      home: _cargandoConfiguracion
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _usuarioLogueado
          ? MenuPrincipal(
              usuarioId: _usuarioId,
              usuarioNombre: _usuarioNombre,
              rolId: _usuarioRolId,
              onCerrarSesion: () async {
                final loginIdActual = _loginId;
                if (!mounted) return;
                setState(() {
                  _usuarioLogueado = false;
                  _usuarioId = 0;
                  _usuarioNombre = '';
                  _usuarioRolId = 0;
                  _loginId = '';
                });
                if (loginIdActual.isNotEmpty) {
                  try {
                    await UsuarioLoginAccess(databaseAccess: DatabaseAccess()).cerrarSesionApi(loginIdActual);
                  } catch (_) {}
                }
                DatabaseAccess.loginId = '';
              },
            )
          : LoginScreen(
              onIngresar: (usuarioId, nombreUsuario, rolId, loginId) async {
                if (!mounted) return;
                DatabaseAccess.loginId = loginId;
                setState(() {
                  _usuarioLogueado = true;
                  _usuarioId = usuarioId;
                  _usuarioNombre = nombreUsuario;
                  _usuarioRolId = rolId;
                  _loginId = loginId;
                });
              },
            ),
      // --- CONFIGURACIÓN DE IDIOMA ---
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // Inglés
        Locale('es', ''), // Español
      ],
      // -----------------------------
    );
  }
}
