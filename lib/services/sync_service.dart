import 'connection_log_service.dart';
import 'database_service.dart';
import 'remote_database_service.dart';

class SyncService {
  final DatabaseService _local;
  final IRemoteDatabaseService _remote;

  SyncService({
    DatabaseService? local,
    IRemoteDatabaseService? remote,
  })  : _local = local ?? DatabaseService.instance,
        _remote = remote ?? RemoteDatabaseService.instance;

  static final SyncService instance = SyncService();

  final _log = ConnectionLogService.instance;

  /// Bidirectional sync: push pending local records then pull new remote records.
  /// Returns true on success, false if the remote is unreachable.
  Future<bool> sync() async {
    _log.info('Iniciando sincronización con MySQL...');
    try {
      final pushed = await _pushPending();
      final pulled = await _pullFromRemote();
      _log.success(
        'Sincronización completada',
        detail: '$pushed enviado(s) al servidor · $pulled recibido(s)',
      );
      return true;
    } catch (e) {
      _log.error(
        'Fallo de sincronización',
        detail: e.toString(),
      );
      return false;
    }
  }

  /// Deletes an evento locally and, if it has a remoteId, remotely too.
  Future<void> deleteEvento(int localId, int? remoteId) async {
    if (remoteId != null) {
      try {
        await _remote.deleteEvento(remoteId);
        _log.info('Evento eliminado del servidor (remoteId: $remoteId)');
      } catch (e) {
        _log.warning(
          'No se pudo eliminar en servidor',
          detail: 'remoteId: $remoteId — ${e.toString()}',
        );
      }
    }
    await _local.deleteEvento(localId);
  }

  Future<int> _pushPending() async {
    final pending = await _local.getUnsyncedEventos();
    int count = 0;
    for (final evento in pending) {
      if (evento.remoteId == null && evento.id != null) {
        final remoteId = await _remote.insertEvento(evento);
        await _local.markSynced(evento.id!, remoteId);
        count++;
      }
    }
    return count;
  }

  Future<int> _pullFromRemote() async {
    final remoteEventos = await _remote.getEventos();
    int count = 0;
    for (final remote in remoteEventos) {
      if (remote.remoteId == null) continue;
      final existing = await _local.getEventoByRemoteId(remote.remoteId!);
      if (existing == null) {
        await _local.insertEvento(remote);
        count++;
      }
    }
    return count;
  }
}
