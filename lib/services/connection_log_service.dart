enum LogType { info, success, warning, error }

class ConnectionLogEntry {
  final DateTime timestamp;
  final LogType type;
  final String message;
  final String? detail;

  const ConnectionLogEntry({
    required this.timestamp,
    required this.type,
    required this.message,
    this.detail,
  });
}

class ConnectionLogService {
  static final ConnectionLogService instance = ConnectionLogService._();
  ConnectionLogService._();

  static const int _maxEntries = 200;
  final List<ConnectionLogEntry> _entries = [];

  /// Returns entries in reverse chronological order (newest first).
  List<ConnectionLogEntry> get entries =>
      List.unmodifiable(_entries.reversed.toList());

  void log(LogType type, String message, {String? detail}) {
    _entries.add(ConnectionLogEntry(
      timestamp: DateTime.now(),
      type: type,
      message: message,
      detail: detail,
    ));
    if (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }
  }

  void info(String message, {String? detail}) =>
      log(LogType.info, message, detail: detail);

  void success(String message, {String? detail}) =>
      log(LogType.success, message, detail: detail);

  void warning(String message, {String? detail}) =>
      log(LogType.warning, message, detail: detail);

  void error(String message, {String? detail}) =>
      log(LogType.error, message, detail: detail);

  void clear() => _entries.clear();
}
