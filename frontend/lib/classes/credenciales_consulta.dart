import 'package:credenciales_web/db/credencial_access.dart';
import 'package:credenciales_web/db/database_access.dart';

class CredencialesConsulta {
  int? credencialId;
  String? descripcion;
  String? usuario;
  String? password;
  String? notas;

  CredencialesConsulta({this.credencialId, this.descripcion, this.usuario, this.password, this.notas});

  factory CredencialesConsulta.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.parse(value.toString());
    }

    return CredencialesConsulta(
      credencialId: json['credencial_id'] != null ? parseInt(json['credencial_id']) : null,
      descripcion: json['descripcion']?.toString(),
      usuario: json['usuario']?.toString(),
      password: json['password']?.toString(),
      notas: json['notas']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (credencialId != null) data['credencial_id'] = credencialId;
    if (descripcion != null) data['descripcion'] = descripcion;
    if (usuario != null) data['usuario'] = usuario;
    if (password != null) data['password'] = password;
    if (notas != null) data['notas'] = notas;
    return data;
  }

  static Future<List<CredencialesConsulta>> lista({
    int? credencialId,
    String? descripcion,
    String? usuario,
    String? notas,
  }) async {
    final db = DatabaseAccess();
    final credencialAccess = CredencialAccess(databaseAccess: db);

    final credencialesDb = await credencialAccess.listaCredencialApi(
      credencialId: credencialId,
      descripcion: descripcion,
      usuario: usuario,
      notas: notas,
    );

    return credencialesDb.map((item) => CredencialesConsulta.fromJson(item)).toList();
  }
}
