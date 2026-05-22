import '../models/materia.dart';
import 'database_service.dart';
import 'session_service.dart';

class MateriaService {
  MateriaService._internal();
  static final MateriaService instance = MateriaService._internal();

  Future<void> init() async {
    final db = await DatabaseService.instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS materias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        user_email TEXT DEFAULT ''
      )
    ''');
  }

  Future<List<Materia>> getMaterias() async {
    final db = await DatabaseService.instance.database;
    final userEmail = SessionService.instance.userEmail ?? '';
    final result = await db.query(
      'materias',
      where: 'user_email = ?',
      whereArgs: [userEmail],
      orderBy: 'nombre ASC',
    );
    return result.map(Materia.fromMap).toList();
  }

  Future<int> insertMateria(String nombre) async {
    final db = await DatabaseService.instance.database;
    return db.insert('materias', {
      'nombre': nombre.trim(),
      'user_email': SessionService.instance.userEmail ?? '',
    });
  }

  Future<void> deleteMateria(int id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('materias', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> existeNombre(String nombre) async {
    final db = await DatabaseService.instance.database;
    final userEmail = SessionService.instance.userEmail ?? '';
    final result = await db.query(
      'materias',
      where: 'nombre = ? AND user_email = ?',
      whereArgs: [nombre.trim(), userEmail],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
