import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _notifications.initialize(initSettings);
  }

  static Future<void> showTramPrompt() async {
    const androidDetails = AndroidNotificationDetails(
      'tram_prompt',
      'Tram Prompt',
      channelDescription: 'Prompt to enable GPS sharing',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Tram Alger',
    );
    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      'Êtes-vous dans le tram?',
      'Activez le partage GPS pour ameliorer les predictions',
      details,
    );
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
