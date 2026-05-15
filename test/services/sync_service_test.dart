import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:agenda_academica/models/evento.dart';
import 'package:agenda_academica/services/database_service.dart';
import 'package:agenda_academica/services/remote_database_service.dart';
import 'package:agenda_academica/services/sync_service.dart';

// ──────────────────────────────────────────────
// Manual mock for the remote service
// ──────────────────────────────────────────────

class MockRemoteDatabaseService implements IRemoteDatabaseService {
  final List<Evento> _store = [];
  int _nextId = 1;
  bool shouldFail = false;

  List<Evento> get store => List.unmodifiable(_store);

  @override
  Future<int> insertEvento(Evento evento) async {
    if (shouldFail) throw Exception('Network error');
    final id = _nextId++;
    _store.add(evento.copyWith(remoteId: id));
    return id;
  }

  @override
  Future<List<Evento>> getEventos() async {
    if (shouldFail) throw Exception('Network error');
    return List.from(_store);
  }

  @override
  Future<void> deleteEvento(int remoteId) async {
    if (shouldFail) throw Exception('Network error');
    _store.removeWhere((e) => e.remoteId == remoteId);
  }

  @override
  Future<void> updateEstado(
    int remoteId,
    String estado,
    String updatedAt,
  ) async {
    if (shouldFail) throw Exception('Network error');
    final idx = _store.indexWhere((e) => e.remoteId == remoteId);
    if (idx != -1) {
      _store[idx] = _store[idx].copyWith(estado: estado, updatedAt: updatedAt);
    }
  }

  @override
  Future<void> close() async {}
}

// ──────────────────────────────────────────────
// Helper: an in-memory DatabaseService for tests
// ──────────────────────────────────────────────

Future<DatabaseService> _makeLocalDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Close any existing singleton database
  try {
    await DatabaseService.instance.close();
  } catch (_) {}

  return DatabaseService.instance;
}

Evento _makeEvento({
  String titulo = 'Test Evento',
  String materia = 'Test Materia',
}) {
  final now = DateTime.now().toIso8601String();
  return Evento(
    titulo: titulo,
    materia: materia,
    tipo: 'Tarea',
    fecha: '2026-06-01',
    hora: '10:00',
    descripcion: 'descripción de prueba',
    createdAt: now,
  );
}

void main() {
  late MockRemoteDatabaseService mockRemote;
  late DatabaseService local;
  late SyncService syncService;

  setUp(() async {
    mockRemote = MockRemoteDatabaseService();
    local = await _makeLocalDb();
    syncService = SyncService(local: local, remote: mockRemote);
  });

  tearDown(() async {
    await local.close();
  });

  group('SyncService.sync()', () {
    test('returns true when remote is reachable', () async {
      final result = await syncService.sync();
      expect(result, isTrue);
    });

    test('returns false when remote is unreachable', () async {
      mockRemote.shouldFail = true;
      final result = await syncService.sync();
      expect(result, isFalse);
    });

    test('pushes unsynced local events to remote', () async {
      final localId = await local.insertEvento(_makeEvento(titulo: 'Tarea A'));

      await syncService.sync();

      expect(mockRemote.store.length, 1);
      expect(mockRemote.store.first.titulo, 'Tarea A');

      final updated = await local.getEventos();
      final synced = updated.firstWhere((e) => e.id == localId);
      expect(synced.synced, isTrue);
      expect(synced.remoteId, isNotNull);
    });

    test('pulls new remote events into local db', () async {
      // Seed remote directly
      mockRemote._store.add(
        _makeEvento(titulo: 'Remote Evento').copyWith(remoteId: 99, synced: true),
      );

      await syncService.sync();

      final localEventos = await local.getEventos();
      expect(localEventos.any((e) => e.titulo == 'Remote Evento'), isTrue);
    });

    test('does not duplicate existing synced events on re-sync', () async {
      await local.insertEvento(_makeEvento(titulo: 'Duplicado'));
      await syncService.sync();
      await syncService.sync(); // second sync

      final localEventos = await local.getEventos();
      final count = localEventos.where((e) => e.titulo == 'Duplicado').length;
      expect(count, 1);
    });

    test('does not push already-synced events', () async {
      await local.insertEvento(_makeEvento(titulo: 'Evento 1'));
      await syncService.sync();

      final remoteCountAfterFirst = mockRemote.store.length;

      // Second sync should not push again
      await syncService.sync();

      expect(mockRemote.store.length, remoteCountAfterFirst);
    });

    test('partial failure: local saves survive remote failure', () async {
      await local.insertEvento(_makeEvento(titulo: 'Local Only'));

      mockRemote.shouldFail = true;
      final result = await syncService.sync();

      expect(result, isFalse);

      // Local event still exists
      final localEventos = await local.getEventos();
      expect(localEventos.any((e) => e.titulo == 'Local Only'), isTrue);
    });
  });

  group('SyncService.deleteEvento()', () {
    test('deletes locally when remoteId is null', () async {
      final localId = await local.insertEvento(_makeEvento());

      await syncService.deleteEvento(localId, null);

      final eventos = await local.getEventos();
      expect(eventos.any((e) => e.id == localId), isFalse);
    });

    test('deletes both locally and remotely when remoteId is set', () async {
      final localId = await local.insertEvento(_makeEvento());
      // Simulate sync so we have a remoteId
      await syncService.sync();

      final synced = (await local.getEventos()).firstWhere((e) => e.id == localId);
      expect(synced.remoteId, isNotNull);

      await syncService.deleteEvento(localId, synced.remoteId);

      final localAfter = await local.getEventos();
      expect(localAfter.any((e) => e.id == localId), isFalse);
      expect(mockRemote.store.any((e) => e.remoteId == synced.remoteId), isFalse);
    });

    test('local deletion succeeds even when remote deletion fails', () async {
      final localId = await local.insertEvento(_makeEvento());
      await syncService.sync();

      final synced = (await local.getEventos()).firstWhere((e) => e.id == localId);

      mockRemote.shouldFail = true;
      await syncService.deleteEvento(localId, synced.remoteId);

      // Local should still be deleted
      final localAfter = await local.getEventos();
      expect(localAfter.any((e) => e.id == localId), isFalse);
    });
  });
}
