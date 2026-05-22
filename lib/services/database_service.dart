import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/evento.dart';
import 'session_service.dart';

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
      version: 3,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE eventos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id INTEGER,
        titulo TEXT NOT NULL,
        materia TEXT NOT NULL,
        tipo TEXT NOT NULL,
        fecha TEXT NOT NULL,
        hora TEXT NOT NULL,
        descripcion TEXT,
        estado TEXT DEFAULT 'pendiente',
        user_email TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE eventos ADD COLUMN remote_id INTEGER');
      await db.execute('ALTER TABLE eventos ADD COLUMN updated_at TEXT');
      await db.execute(
        'ALTER TABLE eventos ADD COLUMN synced INTEGER DEFAULT 0',
      );
      await db.execute(
        'UPDATE eventos SET updated_at = created_at WHERE updated_at IS NULL',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE eventos ADD COLUMN user_email TEXT DEFAULT ''",
      );
    }
  }

  Future<int> insertEvento(Evento evento) async {
    final db = await database;
    final map = Map<String, dynamic>.from(evento.toMap())
      ..remove('id')
      ..['user_email'] = evento.userEmail.isNotEmpty
          ? evento.userEmail
          : (SessionService.instance.userEmail ?? '');
    return db.insert('eventos', map);
  }

  Future<List<Evento>> getEventos() async {
    final db = await database;
    final userEmail = SessionService.instance.userEmail ?? '';
    final result = await db.query(
      'eventos',
      where: 'user_email = ?',
      whereArgs: [userEmail],
      orderBy: 'fecha ASC, hora ASC',
    );
    return result.map(Evento.fromMap).toList();
  }

  Future<List<Evento>> getUnsyncedEventos() async {
    final db = await database;
    final userEmail = SessionService.instance.userEmail ?? '';
    final result = await db.query(
      'eventos',
      where: 'synced = 0 AND user_email = ?',
      whereArgs: [userEmail],
    );
    return result.map(Evento.fromMap).toList();
  }

  Future<Evento?> getEventoByRemoteId(int remoteId) async {
    final db = await database;
    final result = await db.query(
      'eventos',
      where: 'remote_id = ?',
      whereArgs: [remoteId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Evento.fromMap(result.first);
  }

  Future<void> markSynced(int localId, int remoteId) async {
    final db = await database;
    await db.update(
      'eventos',
      {'synced': 1, 'remote_id': remoteId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<int> updateEvento(Evento evento) async {
    final db = await database;
    final map = Map<String, dynamic>.from(evento.toMap())
      ..remove('id')
      ..['updated_at'] = DateTime.now().toIso8601String()
      ..['synced'] = 0;
    return db.update('eventos', map, where: 'id = ?', whereArgs: [evento.id]);
  }

  Future<int> deleteEvento(int id) async {
    final db = await database;
    return db.delete('eventos', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateEstado(int id, String estado) async {
    final db = await database;
    return db.update(
      'eventos',
      {
        'estado': estado,
        'updated_at': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
