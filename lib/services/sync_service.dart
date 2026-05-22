import 'database_service.dart';
import 'remote_database_service.dart';

class SyncService {
  final DatabaseService _local;
  final IRemoteDatabaseService _remote;

  SyncService({DatabaseService? local, IRemoteDatabaseService? remote})
    : _local = local ?? DatabaseService.instance,
      _remote = remote ?? RemoteDatabaseService.instance;

  static final SyncService instance = SyncService();

  /// Bidirectional sync: push pending local records then pull new remote records.
  /// Returns true on success, false if the remote is unreachable.
  Future<bool> sync() async {
    try {
      await _pushPending();
      await _pullFromRemote();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Deletes an evento locally and, if it has a remoteId, remotely too.
  Future<void> deleteEvento(int localId, int? remoteId) async {
    if (remoteId != null) {
      try {
        await _remote.deleteEvento(remoteId);
      } catch (_) {
        // Remote deletion failed — local deletion still proceeds
      }
    }
    await _local.deleteEvento(localId);
  }

  Future<void> _pushPending() async {
    final pending = await _local.getUnsyncedEventos();
    for (final evento in pending) {
      if (evento.remoteId == null && evento.id != null) {
        final remoteId = await _remote.insertEvento(evento);
        await _local.markSynced(evento.id!, remoteId);
      }
    }
  }

  Future<void> _pullFromRemote() async {
    final remoteEventos = await _remote.getEventos();
    for (final remote in remoteEventos) {
      if (remote.remoteId == null) continue;
      final existing = await _local.getEventoByRemoteId(remote.remoteId!);
      if (existing == null) {
        await _local.insertEvento(remote);
      }
    }
  }
}
