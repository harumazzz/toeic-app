import '../../../core/services/notification_service.dart';
import '../../../core/services/word_notification_service.dart';
import '../../vocabulary/domain/entities/word.dart';

class NotificationSchedulerService {
  static Future<bool> requestPermissions() async =>
      NotificationService.requestPermissions();

  static Future<void> scheduleWordNotifications({
    required final List<Word> words,
    required final NotificationFrequency frequency,
    required final int preferredHour,
  }) async {
    final startTime = DateTime.now().copyWith(
      hour: preferredHour,
      minute: 0,
      second: 0,
      millisecond: 0,
    );

    await WordNotificationService.scheduleWordNotifications(
      words: words,
      frequency: frequency,
      startTime: startTime,
    );
  }

  static Future<void> cancelAllWordNotifications() async {
    await WordNotificationService.cancelAllWordNotifications();
  }

  static Future<void> scheduleMotivationalNotifications() async {
    await WordNotificationService.scheduleMotivationalNotifications();
  }

  static Future<void> scheduleStreakReminder({
    required final int currentStreak,
    final DateTime? reminderTime,
  }) async {
    await WordNotificationService.scheduleStreakReminder(
      currentStreak: currentStreak,
      reminderTime: reminderTime,
    );
  }

  static Future<int> getPendingNotificationsCount() async =>
      WordNotificationService.getPendingWordNotificationsCount();
}
