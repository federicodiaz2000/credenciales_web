import 'package:credenciales_web/db/categoria_access.dart';
import 'package:credenciales_web/db/database_access.dart';

class Categoria {
  int id;
  String nombre;

  Categoria({required this.id, required this.nombre});

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(id: json['id'], nombre: json['nombre']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nombre': nombre};
  }

  static Future<List<Categoria>> lista() async {
    final db = DatabaseAccess();
    final access = CategoriaAccess(databaseAccess: db);
    final List<Map<String, dynamic>> categoriasDB = await access.listaCategoriaApi();
    return categoriasDB.map((item) => Categoria.fromJson(item)).toList();
  }

  static Future<void> agregar({required String nombre}) async {
    final db = DatabaseAccess();
    final access = CategoriaAccess(databaseAccess: db);
    await access.agregarCategoriaApi(nombre: nombre);
  }

  static Future<void> actualizar({required int id, required String nombre}) async {
    final db = DatabaseAccess();
    final access = CategoriaAccess(databaseAccess: db);
    await access.modificarCategoriaApi(categoriaId: id, nombre: nombre);
  }

  static Future<void> eliminar({required int id}) async {
    final db = DatabaseAccess();
    final access = CategoriaAccess(databaseAccess: db);
    await access.eliminarCategoriaApi(categoriaId: id);
  }
}
