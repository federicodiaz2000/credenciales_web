import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:credenciales_web/db/database_access.dart';

class CategoriaAccess {
  CategoriaAccess({required this.databaseAccess});

  final DatabaseAccess databaseAccess;

  String get _apiBaseUrl => databaseAccess.apiBaseUrl;

  Map<String, String> get _headers => databaseAccess.headers;

  Future<void> crearTablaCategoriaApi() async {
    final response = await http.post(Uri.parse('$_apiBaseUrl/crearTablaCategoria'), headers: _headers);
    _decodeResponse(response);
  }

  Future<void> agregarDatosPorDefectoCategoriaApi() async {
    final response = await http.post(Uri.parse('$_apiBaseUrl/agregarDatosPorDefectoCategoria'), headers: _headers);
    _decodeResponse(response);
  }

  Future<List<Map<String, dynamic>>> listaCategoriaApi() async {
    final response = await http.get(Uri.parse('$_apiBaseUrl/listaCategoria'), headers: _headers);
    final decoded = _decodeResponse(response);
    final rows = decoded['rows'];
    if (rows is! List) {
      throw Exception('Invalid API response: "rows" is missing or invalid');
    }

    return rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> agregarCategoriaApi({required String nombre}) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/categorias'),
      headers: _headers,
      body: jsonEncode({'nombre': nombre}),
    );
    _decodeResponse(response);
  }

  Future<void> modificarCategoriaApi({required int categoriaId, required String nombre}) async {
    final response = await http.patch(
      Uri.parse('$_apiBaseUrl/categorias/$categoriaId'),
      headers: _headers,
      body: jsonEncode({'nombre': nombre}),
    );
    _decodeResponse(response);
  }

  Future<void> eliminarCategoriaApi({required int categoriaId}) async {
    final response = await http.delete(Uri.parse('$_apiBaseUrl/categorias/$categoriaId'), headers: _headers);
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
