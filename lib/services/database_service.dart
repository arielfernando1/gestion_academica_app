import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/evento.dart';

class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'agenda_academica.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE eventos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        materia TEXT NOT NULL,
        tipo TEXT NOT NULL,
        fecha TEXT NOT NULL,
        hora TEXT NOT NULL,
        descripcion TEXT,
        estado TEXT DEFAULT 'pendiente',
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertEvento(Evento evento) async {
    final db = await database;
    return db.insert('eventos', evento.toMap());
  }

  Future<List<Evento>> getEventos() async {
    final db = await database;

    final result = await db.query(
      'eventos',
      orderBy: 'fecha ASC, hora ASC',
    );

    return result.map((map) => Evento.fromMap(map)).toList();
  }

  Future<int> deleteEvento(int id) async {
    final db = await database;

    return db.delete(
      'eventos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateEstado(int id, String estado) async {
    final db = await database;

    return db.update(
      'eventos',
      {'estado': estado},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}