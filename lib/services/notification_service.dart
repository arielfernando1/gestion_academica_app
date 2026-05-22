import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/evento.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: androidSettings));

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> notificarProximos(List<Evento> eventos) async {
    if (!_initialized) return;
    await _plugin.cancelAll();

    final now = DateTime.now();
    int notifId = 1;

    for (final evento in eventos) {
      if (evento.estado == 'completado') continue;

      try {
        final fecha = DateTime.parse(evento.fecha);
        final parts = evento.hora.split(':');
        final eventoDateTime = DateTime(
          fecha.year,
          fecha.month,
          fecha.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );

        final diff = eventoDateTime.difference(now);
        if (diff.inMinutes <= 0) continue;

        String? body;
        if (diff.inMinutes <= 60) {
          body = '¡Vence en ${diff.inMinutes} min! - ${evento.materia}';
        } else if (diff.inHours <= 24) {
          body = 'Vence hoy a las ${evento.hora} - ${evento.materia}';
        } else if (diff.inDays == 1) {
          body = 'Vence mañana a las ${evento.hora} - ${evento.materia}';
        }

        if (body != null) {
          await _show(notifId++, '${evento.tipo}: ${evento.titulo}', body);
        }
      } catch (_) {}
    }
  }

  Future<void> _show(int id, String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'agenda_recordatorios',
      'Recordatorios',
      channelDescription: 'Tareas y eventos próximos a vencer',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(id, title, body, const NotificationDetails(android: androidDetails));
  }
}
