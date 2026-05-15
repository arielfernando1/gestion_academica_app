import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_academica/models/evento.dart';

void main() {
  group('Evento model', () {
    final baseEvento = Evento(
      id: 1,
      remoteId: 42,
      titulo: 'Examen Final',
      materia: 'Matemáticas',
      tipo: 'Examen',
      fecha: '2026-06-15',
      hora: '09:00',
      descripcion: 'Examen de cálculo integral',
      estado: 'pendiente',
      createdAt: '2026-05-15T10:00:00.000',
      updatedAt: '2026-05-15T10:00:00.000',
      synced: true,
    );

    test('toMap includes all fields', () {
      final map = baseEvento.toMap();

      expect(map['id'], 1);
      expect(map['remote_id'], 42);
      expect(map['titulo'], 'Examen Final');
      expect(map['materia'], 'Matemáticas');
      expect(map['tipo'], 'Examen');
      expect(map['fecha'], '2026-06-15');
      expect(map['hora'], '09:00');
      expect(map['descripcion'], 'Examen de cálculo integral');
      expect(map['estado'], 'pendiente');
      expect(map['created_at'], '2026-05-15T10:00:00.000');
      expect(map['updated_at'], '2026-05-15T10:00:00.000');
      expect(map['synced'], 1);
    });

    test('fromMap reconstructs the same Evento', () {
      final map = baseEvento.toMap();
      final restored = Evento.fromMap(map);

      expect(restored.id, baseEvento.id);
      expect(restored.remoteId, baseEvento.remoteId);
      expect(restored.titulo, baseEvento.titulo);
      expect(restored.materia, baseEvento.materia);
      expect(restored.tipo, baseEvento.tipo);
      expect(restored.fecha, baseEvento.fecha);
      expect(restored.hora, baseEvento.hora);
      expect(restored.descripcion, baseEvento.descripcion);
      expect(restored.estado, baseEvento.estado);
      expect(restored.createdAt, baseEvento.createdAt);
      expect(restored.updatedAt, baseEvento.updatedAt);
      expect(restored.synced, baseEvento.synced);
    });

    test('synced=false is stored as 0 in toMap', () {
      final unsynced = Evento(
        titulo: 'Tarea',
        materia: 'Física',
        tipo: 'Tarea',
        fecha: '2026-06-01',
        hora: '08:00',
        descripcion: '',
        createdAt: '2026-05-15T10:00:00.000',
      );
      expect(unsynced.toMap()['synced'], 0);
    });

    test('fromMap handles missing optional fields with defaults', () {
      final map = {
        'id': 5,
        'remote_id': null,
        'titulo': 'Clase',
        'materia': 'Historia',
        'tipo': 'Clase',
        'fecha': '2026-06-10',
        'hora': '14:00',
        'descripcion': null,
        'estado': null,
        'created_at': '2026-05-10T00:00:00.000',
        'updated_at': null,
        'synced': null,
      };
      final evento = Evento.fromMap(map);

      expect(evento.descripcion, '');
      expect(evento.estado, 'pendiente');
      expect(evento.synced, false);
      expect(evento.remoteId, null);
    });

    test('updatedAt defaults to createdAt when not provided', () {
      final evento = Evento(
        titulo: 'Test',
        materia: 'Test',
        tipo: 'Tarea',
        fecha: '2026-06-01',
        hora: '08:00',
        descripcion: '',
        createdAt: '2026-05-15T10:00:00.000',
      );
      expect(evento.updatedAt, '2026-05-15T10:00:00.000');
    });

    test('copyWith overrides only specified fields', () {
      final modified = baseEvento.copyWith(
        titulo: 'Examen Parcial',
        synced: false,
      );

      expect(modified.titulo, 'Examen Parcial');
      expect(modified.synced, false);
      // Unchanged fields
      expect(modified.materia, baseEvento.materia);
      expect(modified.id, baseEvento.id);
      expect(modified.remoteId, baseEvento.remoteId);
      expect(modified.fecha, baseEvento.fecha);
    });

    test('copyWith preserves remoteId when not specified', () {
      final copy = baseEvento.copyWith(titulo: 'Nuevo título');
      expect(copy.remoteId, 42);
    });
  });
}
