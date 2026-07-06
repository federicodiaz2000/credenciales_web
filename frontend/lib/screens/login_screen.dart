import 'package:flutter/material.dart';
import 'package:credenciales_web/classes/usuario.dart';
import 'package:credenciales_web/db/database_access.dart';
import 'package:credenciales_web/db/usuario_login_access.dart';

class LoginScreen extends StatefulWidget {
  final Future<void> Function(int usuarioId, String nombreUsuario, int rolId, String loginId) onIngresar;

  const LoginScreen({super.key, required this.onIngresar});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _ocultarPassword = true;
  bool _procesando = false;

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    final usuario = _usuarioController.text.trim();
    final password = _passwordController.text;

    if (usuario.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes ingresar usuario y contraseña')));
      return;
    }

    setState(() {
      _procesando = true;
    });

    try {
      final credenciales = await Usuario.obtenerCredencialesLogin(usuario: usuario);
      if (credenciales == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario o contraseña inválidos')));
        }
        return;
      }

      final int usuarioId = credenciales['id'] as int;
      final String nombreUsuario = (credenciales['nombre'] as String?) ?? '';
      final int rolId = (credenciales['rol_id'] as num).toInt();
      final bool tienePassword = credenciales['tiene_password'] as bool? ?? false;
      final String passwordIngresadoEncriptado = Usuario.encriptarPassword(password);

      if (!tienePassword) {
        final bool? confirmarClave = await showDialog<bool>(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Primer ingreso'),
            content: const Text(
              'Este usuario no tiene contraseña asignada.\n\n¿Deseas guardar la contraseña ingresada como contraseña del usuario?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No, Volver')),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sí, aceptar')),
            ],
          ),
        );

        if (confirmarClave != true) {
          _passwordController.clear();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inicio de sesión cancelado')));
          }
          return;
        }

        await Usuario.actualizarPasswordLogin(usuarioId: usuarioId, password: password);
        final loginId = await UsuarioLoginAccess(
          databaseAccess: DatabaseAccess(),
        ).iniciarSesionApi(usuario: usuario, password: passwordIngresadoEncriptado);
        await widget.onIngresar(usuarioId, nombreUsuario, rolId, loginId);
        return;
      }

      try {
        final loginId = await UsuarioLoginAccess(
          databaseAccess: DatabaseAccess(),
        ).iniciarSesionApi(usuario: usuario, password: passwordIngresadoEncriptado);
        await widget.onIngresar(usuarioId, nombreUsuario, rolId, loginId);
      } on CredencialesInvalidasException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario o contraseña inválidos')));
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _procesando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Iniciar sesión', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _usuarioController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: _ocultarPassword,
                      onSubmitted: (_) => _ingresar(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _ocultarPassword = !_ocultarPassword;
                            });
                          },
                          icon: Icon(_ocultarPassword ? Icons.visibility : Icons.visibility_off),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _procesando ? null : _ingresar,
                        child: Text(
                          _procesando ? 'Validando...' : 'Ingresar',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
