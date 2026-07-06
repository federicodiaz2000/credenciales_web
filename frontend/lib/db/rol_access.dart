import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:credenciales_web/db/database_access.dart';

class RolAccess {
  RolAccess({required this.databaseAccess});

  final DatabaseAccess databaseAccess;

  String get _apiBaseUrl => databaseAccess.apiBaseUrl;

  Map<String, String> get _headers => databaseAccess.headers;

  Future<void> crearTablaRolApi() async {
    final response = await http.post(Uri.parse('$_apiBaseUrl/crearTablaRol'), headers: _headers);
    _decodeResponse(response);
  }

  Future<void> agregarDatosPorDefectoRolApi() async {
    final response = await http.post(Uri.parse('$_apiBaseUrl/agregarDatosPorDefectoRol'), headers: _headers);
    _decodeResponse(response);
  }

  Future<List<Map<String, dynamic>>> listaRolApi() async {
    final response = await http.get(Uri.parse('$_apiBaseUrl/listaRol'), headers: _headers);
    final decoded = _decodeResponse(response);
    final rows = decoded['rows'];
    if (rows is! List) {
      throw Exception('Invalid API response: "rows" is missing or invalid');
    }

    return rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

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
