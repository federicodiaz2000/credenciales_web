import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:credenciales_web/db/database_access.dart';

class CredencialesInvalidasException implements Exception {
  const CredencialesInvalidasException();
  @override
  String toString() => 'CredencialesInvalidasException';
}

class UsuarioLoginAccess {
  UsuarioLoginAccess({required this.databaseAccess});

  final DatabaseAccess databaseAccess;

  String get _apiBaseUrl => databaseAccess.apiBaseUrl;

  Map<String, String> get _headers => databaseAccess.headers;

  /// Crea la tabla usuario_login si no existe.
  Future<void> crearTablaUsuarioLoginApi() async {
    final response = await http.post(Uri.parse('$_apiBaseUrl/crearTablaUsuarioLogin'), headers: _headers);
    _decodeResponse(response);
  }

  /// Inicia sesión con [usuario] y [password] (encriptado).
  /// Devuelve el id del registro usuario_login generado.
  /// Lanza [CredencialesInvalidasException] si las credenciales son inválidas (401).
  Future<String> iniciarSesionApi({required String usuario, required String password}) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/usuarioLogin'),
      headers: _headers,
      body: jsonEncode({'usuario': usuario, 'password': password}),
    );
    if (response.statusCode == 401) {
      throw const CredencialesInvalidasException();
    }
    final decoded = _decodeResponse(response);
    final id = decoded['id'];
    if (id == null || id is! String) {
      throw Exception('Respuesta inesperada del servidor: falta el campo "id"');
    }
    return id;
  }

  /// Cierra la sesión correspondiente al [loginId].
  Future<void> cerrarSesionApi(String loginId) async {
    final response = await http.patch(
      Uri.parse('$_apiBaseUrl/usuarioLogin/${Uri.encodeComponent(loginId)}/cerrar'),
      headers: _headers,
    );
    _decodeResponse(response);
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
