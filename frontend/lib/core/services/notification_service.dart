import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  const NotificationService._();

  static FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;

  static Future<void> initialize() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _flutterLocalNotificationsPlugin!.initialize(initializationSettings);
    return;
  }

  static Future<void> push(
    final String title,
    final String description,
  ) async {
    await _flutterLocalNotificationsPlugin!.show(
      DateTime.now().millisecondsSinceEpoch % 0x80000000,
      title,
      description,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'com.haruma.toeic.learn.notification_channel.main',
          'Main',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    return;
  }
}
