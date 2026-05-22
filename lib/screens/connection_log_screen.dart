import 'package:flutter/material.dart';

import '../config/db_config.dart';
import '../services/connection_log_service.dart';
import '../services/database_service.dart';
import '../services/remote_database_service.dart';

class ConnectionLogScreen extends StatefulWidget {
  const ConnectionLogScreen({super.key});

  @override
  State<ConnectionLogScreen> createState() => _ConnectionLogScreenState();
}

class _ConnectionLogScreenState extends State<ConnectionLogScreen> {
  bool? _connected;
  bool _checking = false;
  int _total = 0;
  int _synced = 0;
  int _unsynced = 0;
  List<ConnectionLogEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_checkConnection(), _loadStats()]);
    _refreshLog();
  }

  Future<void> _checkConnection() async {
    setState(() => _checking = true);
    final ok = await RemoteDatabaseService.instance.testConnection();
    if (!mounted) return;
    setState(() {
      _connected = ok;
      _checking = false;
    });
  }

  Future<void> _loadStats() async {
    final all = await DatabaseService.instance.getEventos();
    final unsynced = await DatabaseService.instance.getUnsyncedEventos();
    if (!mounted) return;
    setState(() {
      _total = all.length;
      _unsynced = unsynced.length;
      _synced = _total - _unsynced;
    });
  }

  void _refreshLog() {
    setState(() {
      _entries = ConnectionLogService.instance.entries;
    });
  }

  void _clearLog() {
    ConnectionLogService.instance.clear();
    _refreshLog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de Conexión'),
        actions: [
          IconButton(
            tooltip: 'Limpiar registro',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _entries.isEmpty ? null : _clearLog,
          ),
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatusCard(
              connected: _connected,
              checking: _checking,
              onCheck: _loadAll,
            ),
            const SizedBox(height: 12),
            _StatsCard(
              total: _total,
              synced: _synced,
              unsynced: _unsynced,
            ),
            const SizedBox(height: 16),
            _LogSection(entries: _entries),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.connected,
    required this.checking,
    required this.onCheck,
  });

  final bool? connected;
  final bool checking;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (checking) {
      statusColor = cs.secondary;
      statusIcon = Icons.wifi_find;
      statusLabel = 'Verificando...';
    } else if (connected == true) {
      statusColor = Colors.green.shade600;
      statusIcon = Icons.cloud_done_outlined;
      statusLabel = 'Conectado';
    } else if (connected == false) {
      statusColor = Colors.red.shade600;
      statusIcon = Icons.cloud_off_outlined;
      statusLabel = 'Sin conexión';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.cloud_outlined;
      statusLabel = 'Desconocido';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 10),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (checking) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const Divider(height: 20),
            _infoRow(Icons.dns_outlined, 'Servidor', DbConfig.mysqlHost),
            const SizedBox(height: 4),
            _infoRow(
              Icons.settings_ethernet,
              'Puerto',
              DbConfig.mysqlPort.toString(),
            ),
            const SizedBox(height: 4),
            _infoRow(
              Icons.storage_outlined,
              'Base de datos',
              DbConfig.mysqlDatabase,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: checking ? null : onCheck,
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Verificar conexión'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.total,
    required this.synced,
    required this.unsynced,
  });

  final int total;
  final int synced;
  final int unsynced;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart_outlined),
                SizedBox(width: 8),
                Text(
                  'Base de datos local',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                _StatChip(
                  label: 'Total',
                  value: total,
                  color: Colors.indigo,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Sincronizados',
                  value: synced,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Pendientes',
                  value: unsynced,
                  color: unsynced > 0 ? Colors.orange : Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogSection extends StatelessWidget {
  const _LogSection({required this.entries});

  final List<ConnectionLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(Icons.list_alt_outlined),
              SizedBox(width: 8),
              Text(
                'Registro de actividad',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
        if (entries.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Sin actividad registrada.\nSincroniza para ver eventos aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...entries.map((e) => _LogEntryTile(entry: e)),
      ],
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({required this.entry});

  final ConnectionLogEntry entry;

  static const _icons = {
    LogType.info: Icons.info_outline,
    LogType.success: Icons.check_circle_outline,
    LogType.warning: Icons.warning_amber_outlined,
    LogType.error: Icons.error_outline,
  };

  static const _colors = {
    LogType.info: Colors.blueGrey,
    LogType.success: Colors.green,
    LogType.warning: Colors.orange,
    LogType.error: Colors.red,
  };

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final day = '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
    return '$day $h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final color = _colors[entry.type] ?? Colors.grey;
    final icon = _icons[entry.type] ?? Icons.circle_outlined;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withAlpha(60)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.message,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (entry.detail != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        entry.detail!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatTime(entry.timestamp),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
