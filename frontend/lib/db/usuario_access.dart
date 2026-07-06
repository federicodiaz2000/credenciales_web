import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:credenciales_web/db/database_access.dart';

class UsuarioAccess {
  UsuarioAccess({required this.databaseAccess});

  final DatabaseAccess databaseAccess;

  String get _apiBaseUrl => databaseAccess.apiBaseUrl;

  Map<String, String> get _headers => databaseAccess.headers;

  Future<void> crearTablaUsuarioApi() async {
    final response = await http.post(Uri.parse('$_apiBaseUrl/crearTablaUsuario'), headers: _headers);
    _decodeResponse(response);
  }

  Future<void> agregarDatosPorDefectoUsuarioApi() async {
    final response = await http.post(Uri.parse('$_apiBaseUrl/agregarDatosPorDefectoUsuario'), headers: _headers);
    _decodeResponse(response);
  }

  Future<List<Map<String, dynamic>>> listaUsuarioApi() async {
    final response = await http.get(Uri.parse('$_apiBaseUrl/listaUsuario'), headers: _headers);
    final decoded = _decodeResponse(response);
    final rows = decoded['rows'];
    if (rows is! List) {
      throw Exception('Invalid API response: "rows" is missing or invalid');
    }

    return rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<Map<String, dynamic>?> obtenerCredencialesLoginUsuarioApi({required String usuario}) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/obtenerCredencialesLoginUsuario'),
      headers: _headers,
      body: jsonEncode({'usuario': usuario}),
    );
    final decoded = _decodeResponse(response);
    final row = decoded['row'];
    if (row == null) {
      return null;
    }
    if (row is! Map) {
      throw Exception('Invalid API response: "row" is invalid');
    }

    return Map<String, dynamic>.from(row);
  }

  Future<void> actualizarPasswordLoginApi({required int usuarioId, required String? password}) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/actualizarPasswordLogin'),
      headers: _headers,
      body: jsonEncode({'usuarioId': usuarioId, 'password': password}),
    );
    _decodeResponse(response);
  }

  Future<void> agregarUsuarioApi({
    required String nombre,
    required String email,
    required int rolId,
    required bool activo,
  }) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/usuarios'),
      headers: _headers,
      body: jsonEncode({'nombre': nombre, 'email': email, 'rolId': rolId, 'activo': activo}),
    );
    _decodeResponse(response);
  }

  Future<void> modificarUsuarioApi({
    required int usuarioId,
    required String nombre,
    required String email,
    required int rolId,
    required bool activo,
  }) async {
    final response = await http.patch(
      Uri.parse('$_apiBaseUrl/usuarios/$usuarioId'),
      headers: _headers,
      body: jsonEncode({'nombre': nombre, 'email': email, 'rolId': rolId, 'activo': activo}),
    );
    _decodeResponse(response);
  }

  Future<void> eliminarUsuarioApi({required int usuarioId}) async {
    final response = await http.delete(Uri.parse('$_apiBaseUrl/usuarios/$usuarioId'), headers: _headers);
    _decodeResponse(response);
  }

  Future<Map<String, dynamic>?> obtenerPorIdUsuarioApi({required int usuarioId}) async {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/obtenerPorIdUsuario?usuarioId=$usuarioId'),
      headers: _headers,
    );
    final decoded = _decodeResponse(response);
    final row = decoded['row'];
    if (row == null) {
      return null;
    }
    if (row is! Map) {
      throw Exception('Invalid API response: "row" is invalid');
    }

    return Map<String, dynamic>.from(row);
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
