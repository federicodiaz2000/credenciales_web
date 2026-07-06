import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:credenciales_web/db/database_access.dart';
import 'package:credenciales_web/db/usuario_access.dart';

class Usuario {
  int id;
  String nombre;
  String email;
  int rolId;
  bool activo = true;

  Usuario({required this.id, required this.nombre, required this.email, required this.rolId, this.activo = true});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nombre: json['nombre'],
      email: json['email'],
      rolId: json['rol_id'],
      activo: json['activo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nombre': nombre, 'email': email, 'rol_id': rolId, 'activo': activo};
  }

  // Lista de Usuarios
  static Future<List<Usuario>> lista() async {
    DatabaseAccess db = DatabaseAccess();
    final usuarioAccess = UsuarioAccess(databaseAccess: db);
    final List<Map<String, dynamic>> usuariosDB = await usuarioAccess.listaUsuarioApi();
    final List<Usuario> usuarios = usuariosDB.map((item) => Usuario.fromJson(item)).toList();
    return usuarios;
  }

  // Obtener credenciales de login de un Usuario activo por usuario
  static Future<Map<String, dynamic>?> obtenerCredencialesLogin({required String usuario}) async {
    DatabaseAccess db = DatabaseAccess();
    final usuarioAccess = UsuarioAccess(databaseAccess: db);
    return usuarioAccess.obtenerCredencialesLoginUsuarioApi(usuario: usuario.trim());
  }

  // Asignar o actualizar password de login a un usuario
  static Future<void> actualizarPasswordLogin({required int usuarioId, String? password}) async {
    final passwordEncriptado = password == null ? null : encriptarPassword(password);

    DatabaseAccess db = DatabaseAccess();
    final usuarioAccess = UsuarioAccess(databaseAccess: db);
    await usuarioAccess.actualizarPasswordLoginApi(usuarioId: usuarioId, password: passwordEncriptado);
  }

  static String encriptarPassword(String passwordPlano) {
    final digest = sha256.convert(utf8.encode(passwordPlano));
    return digest.toString().substring(0, 30);
  }

  static Future<Usuario?> obtenerPorId(int usuarioId) async {
    DatabaseAccess db = DatabaseAccess();
    final usuarioAccess = UsuarioAccess(databaseAccess: db);
    final usuarioDb = await usuarioAccess.obtenerPorIdUsuarioApi(usuarioId: usuarioId);

    if (usuarioDb == null) {
      return null;
    }

    return Usuario.fromJson(usuarioDb);
  }

  static Future<void> agregar({
    required String nombre,
    required String email,
    required int rolId,
    required bool activo,
  }) async {
    DatabaseAccess db = DatabaseAccess();
    final usuarioAccess = UsuarioAccess(databaseAccess: db);
    await usuarioAccess.agregarUsuarioApi(nombre: nombre, email: email, rolId: rolId, activo: activo);
  }

  static Future<void> actualizar({
    required int id,
    required String nombre,
    required String email,
    required int rolId,
    required bool activo,
  }) async {
    DatabaseAccess db = DatabaseAccess();
    final usuarioAccess = UsuarioAccess(databaseAccess: db);
    await usuarioAccess.modificarUsuarioApi(usuarioId: id, nombre: nombre, email: email, rolId: rolId, activo: activo);
  }

  static Future<void> eliminar({required int id}) async {
    DatabaseAccess db = DatabaseAccess();
    final usuarioAccess = UsuarioAccess(databaseAccess: db);
    await usuarioAccess.eliminarUsuarioApi(usuarioId: id);
  }
}
