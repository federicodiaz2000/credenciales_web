import 'package:credenciales_web/db/database_access.dart';
import 'package:credenciales_web/db/rol_access.dart';

class Rol {
  int id;
  String nombre;

  Rol({required this.id, required this.nombre});

  factory Rol.fromJson(Map<String, dynamic> json) {
    return Rol(id: json['id'], nombre: json['nombre']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nombre': nombre};
  }

  // Devolver lista de roles
  static Future<List<Rol>> lista() async {
    DatabaseAccess db = DatabaseAccess();
    final rolAccess = RolAccess(databaseAccess: db);
    final List<Map<String, dynamic>> rolesDB = await rolAccess.listaRolApi();
    final List<Rol> roles = rolesDB.map((item) => Rol.fromJson(item)).toList();
    return roles;
  }
}
