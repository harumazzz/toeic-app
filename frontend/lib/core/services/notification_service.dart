import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  const NotificationService._();

  static FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;

  static Future<void> initialize() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Initialize timezone
    tz.initializeTimeZones();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _flutterLocalNotificationsPlugin!.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    return;
  }

  static void _onDidReceiveNotificationResponse(
    final NotificationResponse notificationResponse,
  ) {
    // Handle notification tap here
    // You can navigate to specific screens based on the payload
  }

  static Future<bool> requestPermissions() async {
    final androidImplementation = _flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final iosImplementation = _flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      try {
        await androidImplementation.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('Exact alarm permission request failed: $e');
      }

      return true;
    }

    if (iosImplementation != null) {
      final result = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }

    return false;
  }

  static Future<void> push(
    final String title,
    final String description, {
    final String? payload,
  }) async {
    await _flutterLocalNotificationsPlugin!.show(
      DateTime.now().millisecondsSinceEpoch % 0x80000000,
      title,
      description,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'com.haruma.toeic.learn.notification_channel.main',
          'Main',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
    return;
  }

  static Future<void> scheduleNotification({
    required final int id,
    required final String title,
    required final String body,
    required final DateTime scheduledTime,
    final String? payload,
  }) async {
    try {
      // First try with exact scheduling
      await _flutterLocalNotificationsPlugin!.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'com.haruma.toeic.learn.notification_channel.scheduled',
            'Scheduled Word Learning',
            channelDescription: 'Notifications for scheduled word learning',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // If exact scheduling fails, fall back to inexact scheduling
      debugPrint('Exact scheduling failed, falling back to inexact: $e');
      try {
        await _flutterLocalNotificationsPlugin!.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'com.haruma.toeic.learn.notification_channel.scheduled',
              'Scheduled Word Learning',
              channelDescription: 'Notifications for scheduled word learning',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (fallbackError) {
        debugPrint('Both exact and inexact scheduling failed: $fallbackError');
        // Even inexact scheduling failed, skip this notification
      }
    }
  }

  static Future<void> scheduleRepeatingNotification({
    required final int id,
    required final String title,
    required final String body,
    required final DateTime scheduledTime,
    required final RepeatInterval repeatInterval,
    final String? payload,
  }) async {
    try {
      await _flutterLocalNotificationsPlugin!.periodicallyShow(
        id,
        title,
        body,
        repeatInterval,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'com.haruma.toeic.learn.notification_channel.scheduled',
            'Scheduled Word Learning',
            channelDescription: 'Notifications for scheduled word learning',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint(
        'Exact repeating scheduling failed, falling back to inexact: $e',
      );
      try {
        await _flutterLocalNotificationsPlugin!.periodicallyShow(
          id,
          title,
          body,
          repeatInterval,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'com.haruma.toeic.learn.notification_channel.scheduled',
              'Scheduled Word Learning',
              channelDescription: 'Notifications for scheduled word learning',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (fallbackError) {
        debugPrint(
          'Both exact and inexact repeating scheduling failed: $fallbackError',
        );
      }
    }
  }

  static Future<void> cancelNotification(final int id) async {
    await _flutterLocalNotificationsPlugin!.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin!.cancelAll();
  }

  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async =>
      _flutterLocalNotificationsPlugin!.pendingNotificationRequests();
}
