import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:credenciales_web/db/database_access.dart';

class CredencialAccess {
  CredencialAccess({required this.databaseAccess});

  final DatabaseAccess databaseAccess;

  String get _apiBaseUrl => databaseAccess.apiBaseUrl;

  Map<String, String> get _headers => databaseAccess.headers;

  Future<void> crearTablaCredencialApi() async {
    final response = await http.post(Uri.parse('$_apiBaseUrl/crearTablaCredencial'), headers: _headers);
    _decodeResponse(response);
  }

  Future<List<Map<String, dynamic>>> listaCredencialApi({
    int? credencialId,
    String? descripcion,
    String? usuario,
  }) async {
    final queryParams = <String, String>{
      if (credencialId != null) 'credencial_id': credencialId.toString(),
      if (descripcion != null && descripcion.trim().isNotEmpty) 'descripcion': descripcion.trim(),
      if (usuario != null && usuario.trim().isNotEmpty) 'usuario': usuario.trim(),
    };

    // Usamos el endpoint `/listaCredencial` que devuelve las filas según `Credencial.lista` en el backend.
    final uri = Uri.parse('$_apiBaseUrl/listaCredencial').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    final decoded = _decodeResponse(response);
    final rows = decoded['rows'];
    if (rows is! List) {
      throw Exception('Invalid API response: "rows" is missing or invalid');
    }

    return rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<int> proximoCodigoCredencialApi() async {
    final uri = Uri.parse('$_apiBaseUrl/credenciales/proximoCodigo');
    final response = await http.get(uri, headers: _headers);
    final decoded = _decodeResponse(response);
    return decoded['proximo_codigo'] as int;
  }

  Future<Map<String, dynamic>?> consultaPorIdCredencialApi({required int credencialId}) async {
    final uri = Uri.parse(
      '$_apiBaseUrl/consultaPorIdCredencial',
    ).replace(queryParameters: {'credencial_id': credencialId.toString()});

    final response = await http.get(uri, headers: _headers);
    final decoded = _decodeResponse(response);
    final row = decoded['row'];

    if (row == null) {
      return null;
    }
    if (row is! Map) {
      throw Exception('Invalid API response: "row" is missing or invalid');
    }

    return Map<String, dynamic>.from(row);
  }

  Future<void> eliminarCredencialApi({required int credencialId}) async {
    final uri = Uri.parse('$_apiBaseUrl/credenciales/$credencialId');
    final response = await http.delete(uri, headers: _headers);
    _decodeResponse(response);
  }

  Future<void> agregarCredencialApi({
    required int credencialId,
    String? descripcion,
    String? usuario,
    String? password,
    String? notas,
  }) async {
    final uri = Uri.parse('$_apiBaseUrl/credenciales');
    final body = jsonEncode({
      'credencial_id': credencialId,
      'descripcion': descripcion,
      'usuario': usuario,
      'password': password,
      'notas': notas,
    });
    final response = await http.post(uri, headers: _headers, body: body);
    _decodeResponse(response);
  }

  Future<void> modificarCredencialApi({
    required int credencialId,
    String? descripcion,
    String? usuario,
    String? password,
    String? notas,
  }) async {
    final uri = Uri.parse('$_apiBaseUrl/credenciales/$credencialId');
    final body = jsonEncode({'descripcion': descripcion, 'usuario': usuario, 'password': password, 'notas': notas});
    final response = await http.patch(uri, headers: _headers, body: body);
    _decodeResponse(response);
  }

  /// Sube una imagen (marca o senial) para la credencial indicada.
  /// [tipo] debe ser 'marca' o 'senial'.

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid API response format');
    }

    if (response.statusCode >= 400) {
      final detail = decoded['detail']?.toString() ?? response.body;
      throw Exception('API error (${response.statusCode}): $detail');
    }

    return decoded;
  }
}
