import 'package:credenciales_web/db/credencial_access.dart';
import 'package:credenciales_web/db/database_access.dart';
// CredencialTitular eliminado: la representación de titulares se delega al backend.

class Credencial {
  int credencialId;
  String? descripcion;
  String? usuario;
  String? password;
  String? notas;
  String? numeroRenspa; // legacy optional
  String? credencialVencimiento; // legacy optional
  String? expediente; // legacy optional
  String? oficinaCargaCodigo; // legacy optional
  int? oficinaTransaccion; // legacy optional
  int? establecimientoCuit; // legacy optional
  String? titularDomicilio; // legacy optional

  Credencial({
    required this.credencialId,
    this.descripcion,
    this.usuario,
    this.password,
    this.notas,
    this.numeroRenspa,
    this.credencialVencimiento,
    this.expediente,
    this.oficinaCargaCodigo,
    this.oficinaTransaccion,
    this.establecimientoCuit,
    this.titularDomicilio,
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

    int? parseNullableInt(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      return int.tryParse(value.toString());
    }

    return Credencial(
      credencialId: parseInt(json['boleto_codigo'] ?? json['credencial_id']),
      descripcion: json['descripcion']?.toString() ?? json['senial_descripcion']?.toString(),
      usuario: json['usuario']?.toString() ?? json['titular_descripcion']?.toString(),
      password: json['password']?.toString(),
      notas: json['notas']?.toString() ?? json['observaciones']?.toString(),
      numeroRenspa: json['numero_renspa']?.toString(),
      credencialVencimiento: json['boleto_vencimiento']?.toString(),
      expediente: json['expediente']?.toString(),
      oficinaCargaCodigo: json['oficina_carga_codigo']?.toString(),
      oficinaTransaccion: parseNullableInt(json['oficina_transaccion']),
      establecimientoCuit: parseNullableInt(json['establecimiento_cuit']),
      titularDomicilio: json['titular_domicilio']?.toString(),
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
    String? usuario,
    String? password,
    String? notas,
  }) async {
    final db = DatabaseAccess();
    final credencialAccess = CredencialAccess(databaseAccess: db);
    await credencialAccess.agregarCredencialApi(
      credencialId: credencialId,
      descripcion: descripcion,
      usuario: usuario,
      password: password,
      notas: notas,
    );
  }

  static Future<void> modificar({
    required int credencialId,
    String? descripcion,
    String? usuario,
    String? password,
    String? notas,
  }) async {
    final db = DatabaseAccess();
    final credencialAccess = CredencialAccess(databaseAccess: db);
    await credencialAccess.modificarCredencialApi(
      credencialId: credencialId,
      descripcion: descripcion,
      usuario: usuario,
      password: password,
      notas: notas,
    );
  }

  // Titulares: manejado en backend; las conversiones fueron removidas.
}
