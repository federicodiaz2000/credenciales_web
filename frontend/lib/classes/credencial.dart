import 'package:credenciales_web/db/credencial_access.dart';
import 'package:credenciales_web/db/database_access.dart';

class Credencial {
  int credencialId;
  String? descripcion;
  String? usuario;
  String? password;
  String? notas;
  int? categoriaId;
  String? categoriaNombre;

  Credencial({
    required this.credencialId,
    this.descripcion,
    this.usuario,
    this.password,
    this.notas,
    this.categoriaId,
    this.categoriaNombre,
  });

  factory Credencial.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      return int.parse(value.toString());
    }

    return Credencial(
      credencialId: parseInt(json['credencial_id']),
      descripcion: json['descripcion']?.toString(),
      usuario: json['usuario']?.toString(),
      password: json['password']?.toString(),
      notas: json['notas']?.toString() ?? json['observaciones']?.toString(),
      categoriaId: json['categoria_id'] != null ? int.tryParse(json['categoria_id'].toString()) : null,
      categoriaNombre: json['categoria_nombre']?.toString(),
    );
  }

  static Future<int> proximoCodigo() async {
    final db = DatabaseAccess();
    final credencialAccess = CredencialAccess(databaseAccess: db);
    return credencialAccess.proximoCodigoCredencialApi();
  }

  static Future<Credencial?> consultar({required int credencialId}) async {
    final db = DatabaseAccess();
    final credencialAccess = CredencialAccess(databaseAccess: db);
    final credencialDb = await credencialAccess.consultaPorIdCredencialApi(credencialId: credencialId);
    if (credencialDb == null) {
      return null;
    }
    final credencial = Credencial.fromJson(credencialDb);
    return credencial;
  }

  static Future<void> eliminar(int credencialId) async {
    final db = DatabaseAccess();
    final credencialAccess = CredencialAccess(databaseAccess: db);
    await credencialAccess.eliminarCredencialApi(credencialId: credencialId);
  }

  static Future<void> agregar({
    required int credencialId,
    String? descripcion,
    int? categoriaId,
    String? usuario,
    String? password,
    String? notas,
  }) async {
    final db = DatabaseAccess();
    final credencialAccess = CredencialAccess(databaseAccess: db);
    await credencialAccess.agregarCredencialApi(
      credencialId: credencialId,
      descripcion: descripcion,
      categoriaId: categoriaId,
      usuario: usuario,
      password: password,
      notas: notas,
    );
  }

  static Future<void> modificar({
    required int credencialId,
    String? descripcion,
    int? categoriaId,
    String? usuario,
    String? password,
    String? notas,
  }) async {
    final db = DatabaseAccess();
    final credencialAccess = CredencialAccess(databaseAccess: db);
    await credencialAccess.modificarCredencialApi(
      credencialId: credencialId,
      descripcion: descripcion,
      categoriaId: categoriaId,
      usuario: usuario,
      password: password,
      notas: notas,
    );
  }
}
