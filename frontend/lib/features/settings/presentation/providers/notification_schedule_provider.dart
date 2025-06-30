import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/services/word_notification_service.dart';
import '../../../vocabulary/domain/entities/word.dart';
import '../../domain/entities/setting.dart';
import 'setting_provider.dart';

part 'notification_schedule_provider.g.dart';

@riverpod
class NotificationScheduler extends _$NotificationScheduler {
  @override
  Future<void> build() async {
    // Initial build - no-op
  }

  Future<void> scheduleWordNotifications({
    required final List<Word> words,
  }) async {
    final settingAsync = ref.read(settingNotifierProvider);

    if (settingAsync.hasValue) {
      final setting = settingAsync.value!;

      if (setting.notificationEnabled && setting.wordNotificationEnabled) {
        final frequency = _convertToServiceFrequency(
          setting.wordNotificationFrequency,
        );
        final startTime = DateTime.now().copyWith(
          hour: setting.wordNotificationHour,
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
    }
  }

  Future<void> requestNotificationPermissions() async {
    // Request permissions from the system
    await NotificationService.requestPermissions();
  }

  Future<void> cancelAllWordNotifications() async {
    await WordNotificationService.cancelAllWordNotifications();
  }

  NotificationFrequency _convertToServiceFrequency(
    final WordNotificationFrequency frequency,
  ) {
    switch (frequency) {
      case WordNotificationFrequency.daily:
        return NotificationFrequency.daily;
      case WordNotificationFrequency.twiceDaily:
        return NotificationFrequency.twiceDaily;
      case WordNotificationFrequency.threeTimesDaily:
        return NotificationFrequency.threeTimesDaily;
      case WordNotificationFrequency.hourly:
        return NotificationFrequency.hourly;
    }
  }
}
