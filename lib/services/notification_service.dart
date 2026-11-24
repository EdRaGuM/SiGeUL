import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz; // <-- Corrección aquí
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initNotification() async {
    // Inicializar zonas horarias correctamente
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Crear canal de notificación con máxima prioridad para Android 8+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'channel_agua_id',
      'Recordatorio de Hidratación',
      description: 'Canal para alertas de toma de agua',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Solicitar permisos de notificación (Android 13+)
  static Future<bool> pedirPermisos() async {
    final androidImplementation =
    _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
      return granted ?? false;
    }
    return false;
  }

  // Programar la notificación para que suene exactamente en 1 minuto
  static Future<void> programarNotificacionAgua() async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime scheduledDate = now.add(const Duration(minutes: 1));

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_agua_id',
      'Recordatorio de Hidratación',
      channelDescription: 'Canal para alertas de toma de agua',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      0,
      '¡Hora de tomar agua! 💧',
      'Es momento de tomar un vaso de agua para mantenerte hidratado.',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Cancelar todas las notificaciones activas
  static Future<void> cancelarNotificaciones() async {
    await _notificationsPlugin.cancelAll();
  }
}