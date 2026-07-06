import 'package:credenciales_web/db/credencial_access.dart';
import 'package:credenciales_web/db/database_access.dart';

class CredencialesConsulta {
  int? credencialId;
  String? descripcion;
  String? usuario;
  String? notas;

  CredencialesConsulta({this.credencialId, this.descripcion, this.usuario, this.notas});

  factory CredencialesConsulta.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.parse(value.toString());
    }

    return CredencialesConsulta(
      credencialId: json['credencial_id'] != null
          ? parseInt(json['credencial_id'])
          : (json['boleto_codigo'] != null ? parseInt(json['boleto_codigo']) : null),
      descripcion: json['descripcion']?.toString() ?? json['senial_descripcion']?.toString(),
      usuario: json['usuario']?.toString() ?? json['titular_descripcion']?.toString(),
      notas:
          json['notas']?.toString() ??
          json['observaciones']?.toString() ??
          json['establecimiento_descripcion']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (credencialId != null) data['credencial_id'] = credencialId;
    if (descripcion != null) data['descripcion'] = descripcion;
    if (usuario != null) data['usuario'] = usuario;
    if (notas != null) data['notas'] = notas;
    return data;
  }

  static Future<List<CredencialesConsulta>> lista({
    int? credencialId,
    String? renspa,
    String? senialDescripcion,
    String? expediente,
    String? oficinaCargaCodigo,
    int? oficinaTransaccion,
    int? titularNumeroDocumento,
    int? establecimientoCuit,
    String? titularDescripcion,
    String? titularTelefono,
    String? titularDomicilio,
    String? establecimientoDescripcion,
  }) async {
    final db = DatabaseAccess();
    final credencialAccess = CredencialAccess(databaseAccess: db);

    final credencialesDb = await credencialAccess.listaCredencialApi(
      credencialId: credencialId,
      descripcion: senialDescripcion ?? titularDescripcion ?? establecimientoDescripcion ?? renspa,
      usuario: null,
    );

    return credencialesDb.map((item) => CredencialesConsulta.fromJson(item)).toList();
  }
}
