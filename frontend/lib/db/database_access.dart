import 'package:credenciales_web/db/categoria_access.dart';
import 'package:http/http.dart' as http;
import 'package:credenciales_web/db/credencial_access.dart';
import 'package:credenciales_web/db/rol_access.dart';
import 'package:credenciales_web/db/usuario_access.dart';
import 'package:credenciales_web/db/usuario_login_access.dart';
import '../config/environment.dart';

class DatabaseAccess {
  DatabaseAccess({String? apiBaseUrl, String? apiKey})
    : apiBaseUrl = apiBaseUrl ?? AppEnvironment.apiBaseUrl,
      apiKey = apiKey ?? AppEnvironment.apiKey;

  final String apiBaseUrl;
  final String apiKey;

  static String loginId = '';

  /// Headers JSON con API Key y, si hay sesión activa, X-Login-Id.
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'X-API-Key': apiKey,
    if (loginId.isNotEmpty) 'X-Login-Id': loginId,
  };

  /// Headers de autenticación sin Content-Type (para multipart/form-data).
  Map<String, String> get authHeaders => {'X-API-Key': apiKey, if (loginId.isNotEmpty) 'X-Login-Id': loginId};

  static Future<void> checkConnection({String? apiBaseUrl, String? apiKey}) async {
    final baseUrl = apiBaseUrl ?? AppEnvironment.apiBaseUrl;
    final key = apiKey ?? AppEnvironment.apiKey;

    final response = await http.get(Uri.parse('$baseUrl/health'), headers: {'X-API-Key': key});

    if (response.statusCode >= 400) {
      throw Exception('Health check failed (${response.statusCode}): ${response.body}');
    }
  }

  static Future<void> crearBaseDeDatos({String? apiBaseUrl, String? apiKey}) async {
    final db = DatabaseAccess(apiBaseUrl: apiBaseUrl, apiKey: apiKey);
    final rolAccess = RolAccess(databaseAccess: db);
    final usuarioAccess = UsuarioAccess(databaseAccess: db);
    final usuarioLoginAccess = UsuarioLoginAccess(databaseAccess: db);
    final categoriaAccess = CategoriaAccess(databaseAccess: db);
    final credencialAccess = CredencialAccess(databaseAccess: db);

    await rolAccess.crearTablaRolApi();
    await usuarioAccess.crearTablaUsuarioApi();
    await usuarioLoginAccess.crearTablaUsuarioLoginApi();
    await categoriaAccess.crearTablaCategoriaApi();
    await credencialAccess.crearTablaCredencialApi();

    await rolAccess.agregarDatosPorDefectoRolApi();
    await usuarioAccess.agregarDatosPorDefectoUsuarioApi();
    await categoriaAccess.agregarDatosPorDefectoCategoriaApi();
  }
}
