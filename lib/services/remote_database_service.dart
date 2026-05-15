import 'package:mysql_client/mysql_client.dart';

import '../config/db_config.dart';
import '../models/evento.dart';

abstract class IRemoteDatabaseService {
  Future<int> insertEvento(Evento evento);
  Future<List<Evento>> getEventos();
  Future<void> deleteEvento(int remoteId);
  Future<void> updateEstado(int remoteId, String estado, String updatedAt);
  Future<bool> testConnection();
  Future<void> close();
}

class RemoteDatabaseService implements IRemoteDatabaseService {
  static final RemoteDatabaseService instance = RemoteDatabaseService._();
  RemoteDatabaseService._();

  MySQLConnection? _connection;

  Future<MySQLConnection> _getConnection() async {
    if (_connection != null) {
      try {
        await _connection!.execute('SELECT 1');
        return _connection!;
      } catch (_) {
        _connection = null;
      }
    }
    return _connect();
  }

  Future<MySQLConnection> _connect() async {
    final conn = await MySQLConnection.createConnection(
      host: DbConfig.mysqlHost,
      port: DbConfig.mysqlPort,
      userName: DbConfig.mysqlUser,
      password: DbConfig.mysqlPassword,
      databaseName: DbConfig.mysqlDatabase,
    );
    await conn.connect();
    _connection = conn;
    await _ensureTableExists();
    return conn;
  }

  Future<void> _ensureTableExists() async {
    await _connection!.execute('''
      CREATE TABLE IF NOT EXISTS eventos (
        id INT AUTO_INCREMENT PRIMARY KEY,
        titulo VARCHAR(255) NOT NULL,
        materia VARCHAR(255) NOT NULL,
        tipo VARCHAR(100) NOT NULL,
        fecha VARCHAR(20) NOT NULL,
        hora VARCHAR(20) NOT NULL,
        descripcion TEXT,
        estado VARCHAR(50) DEFAULT 'pendiente',
        created_at VARCHAR(30) NOT NULL,
        updated_at VARCHAR(30) NOT NULL
      )
    ''');
  }

  @override
  Future<int> insertEvento(Evento evento) async {
    final conn = await _getConnection();
    final result = await conn.execute(
      'INSERT INTO eventos '
      '(titulo, materia, tipo, fecha, hora, descripcion, estado, created_at, updated_at) '
      'VALUES (:titulo, :materia, :tipo, :fecha, :hora, :descripcion, :estado, :created_at, :updated_at)',
      {
        'titulo': evento.titulo,
        'materia': evento.materia,
        'tipo': evento.tipo,
        'fecha': evento.fecha,
        'hora': evento.hora,
        'descripcion': evento.descripcion,
        'estado': evento.estado,
        'created_at': evento.createdAt,
        'updated_at': evento.updatedAt,
      },
    );
    return result.lastInsertID.toInt();
  }

  @override
  Future<List<Evento>> getEventos() async {
    final conn = await _getConnection();
    final result = await conn.execute(
      'SELECT * FROM eventos ORDER BY fecha ASC, hora ASC',
    );
    return result.rows.map((row) {
      return Evento(
        remoteId: int.tryParse(row.colByName('id') ?? ''),
        titulo: row.colByName('titulo') ?? '',
        materia: row.colByName('materia') ?? '',
        tipo: row.colByName('tipo') ?? '',
        fecha: row.colByName('fecha') ?? '',
        hora: row.colByName('hora') ?? '',
        descripcion: row.colByName('descripcion') ?? '',
        estado: row.colByName('estado') ?? 'pendiente',
        createdAt: row.colByName('created_at') ?? '',
        updatedAt: row.colByName('updated_at'),
        synced: true,
      );
    }).toList();
  }

  @override
  Future<void> deleteEvento(int remoteId) async {
    final conn = await _getConnection();
    await conn.execute(
      'DELETE FROM eventos WHERE id = :id',
      {'id': remoteId},
    );
  }

  @override
  Future<void> updateEstado(
    int remoteId,
    String estado,
    String updatedAt,
  ) async {
    final conn = await _getConnection();
    await conn.execute(
      'UPDATE eventos SET estado = :estado, updated_at = :updated_at WHERE id = :id',
      {'estado': estado, 'updated_at': updatedAt, 'id': remoteId},
    );
  }

  @override
  Future<bool> testConnection() async {
    try {
      await _getConnection();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
}
