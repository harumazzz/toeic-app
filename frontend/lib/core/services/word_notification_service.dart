// ignore_for_file: lines_longer_than_80_chars

import 'dart:math';

import '../../features/progress/domain/entities/progress.dart';
import '../../features/vocabulary/domain/entities/word.dart';
import '../../i18n/strings.g.dart';
import 'notification_service.dart';

enum NotificationFrequency {
  daily,
  twiceDaily,
  threeTimesDaily,
  hourly,
}

class WordNotificationService {
  static const int _baseNotificationId = 1000;

  /// Schedule daily word notifications
  static Future<void> scheduleWordNotifications({
    required final List<Word> words,
    required final NotificationFrequency frequency,
    final DateTime? startTime,
  }) async {
    // Cancel existing word notifications first
    await cancelAllWordNotifications();

    final now = DateTime.now();
    final scheduleTime =
        startTime ??
        DateTime(now.year, now.month, now.day, 9); // Default to 9 AM

    final intervals = _getNotificationIntervals(frequency);

    for (int i = 0; i < words.length && i < 10; i++) {
      // Limit to 10 words to avoid spam
      final word = words[i];

      for (int j = 0; j < intervals.length; j++) {
        final notificationTime = scheduleTime.add(
          Duration(
            days: i,
            hours: intervals[j],
          ),
        );

        if (notificationTime.isAfter(now)) {
          final meaning =
              word.shortMean ?? t.notifications.wordLearning.expandVocabulary;
          var bodyText = t.notifications.wordLearning.learnWordMessage;
          bodyText = bodyText.replaceFirst('{}', word.word);
          bodyText = bodyText.replaceFirst('{}', meaning);

          await NotificationService.scheduleNotification(
            id: _baseNotificationId + (i * 10) + j,
            title: t.notifications.wordLearning.timeToLearnNewWord,
            body: bodyText,
            scheduledTime: notificationTime,
            payload: 'word_${word.id}',
          );
        }
      }
    }
  }

  static Future<void> scheduleReviewNotifications({
    required final List<WordProgress> progressList,
  }) async {
    final now = DateTime.now();

    for (final wordProgress in progressList) {
      if (wordProgress.progress.nextReviewAt.isAfter(now)) {
        final notificationTime = wordProgress.progress.nextReviewAt.subtract(
          const Duration(hours: 1),
        );

        if (notificationTime.isAfter(now)) {
          await NotificationService.scheduleNotification(
            id: _baseNotificationId + 500 + wordProgress.word.id,
            title: t.notifications.wordLearning.timeForWordReview,
            body: t.notifications.wordLearning.reviewWordMessage.replaceAll(
              '{}',
              wordProgress.word.word,
            ),
            scheduledTime: notificationTime,
            payload: 'review_${wordProgress.word.id}',
          );
        }
      }
    }
  }

  /// Schedule motivational notifications to encourage learning
  static Future<void> scheduleMotivationalNotifications() async {
    final motivationalMessages = [
      t.notifications.motivational.keepGoing,
      t.notifications.motivational.greatJob,
      t.notifications.motivational.boostSkills,
      t.notifications.motivational.wordADay,
      t.notifications.motivational.dedicationInspiring,
    ];

    final now = DateTime.now();
    final random = Random();

    // Schedule 5 motivational notifications over the next week
    for (int i = 0; i < 5; i++) {
      final scheduledTime = now.add(
        Duration(
          days: i + 1,
          hours: 10 + random.nextInt(8), // Random time between 10 AM and 6 PM
          minutes: random.nextInt(60),
        ),
      );

      await NotificationService.scheduleNotification(
        id: _baseNotificationId + 100 + i,
        title: t.notifications.wordLearning.vocabularyLearningTip,
        body: motivationalMessages[i],
        scheduledTime: scheduledTime,
        payload: 'motivation',
      );
    }
  }

  /// Schedule a streak reminder notification
  static Future<void> scheduleStreakReminder({
    required final int currentStreak,
    final DateTime? reminderTime,
  }) async {
    final now = DateTime.now();
    final scheduleTime =
        reminderTime ??
        DateTime(
          now.year,
          now.month,
          now.day + 1,
          20,
        );

    if (scheduleTime.isAfter(now)) {
      await NotificationService.scheduleNotification(
        id: _baseNotificationId + 200,
        title: t.notifications.wordLearning.maintainYourStreak,
        body: t.notifications.wordLearning.streakMessage.replaceAll(
          '{}',
          currentStreak.toString(),
        ),
        scheduledTime: scheduleTime,
        payload: 'streak_reminder',
      );
    }
  }

  /// Cancel all word-related notifications
  static Future<void> cancelAllWordNotifications() async {
    // Cancel word learning notifications (1000-1999)
    for (int i = _baseNotificationId; i < _baseNotificationId + 1000; i++) {
      await NotificationService.cancelNotification(i);
    }
  }

  /// Get notification intervals based on frequency
  static List<int> _getNotificationIntervals(
    final NotificationFrequency frequency,
  ) {
    switch (frequency) {
      case NotificationFrequency.daily:
        return [0]; // Once at the base time
      case NotificationFrequency.twiceDaily:
        return [0, 12]; // Morning and evening
      case NotificationFrequency.threeTimesDaily:
        return [0, 8, 16]; // Morning, afternoon, evening
      case NotificationFrequency.hourly:
        return List.generate(
          12,
          (final index) => index,
        ); // Every hour for 12 hours
    }
  }

  /// Schedule a custom word notification
  static Future<void> scheduleCustomWordNotification({
    required final Word word,
    required final DateTime scheduledTime,
    final String? customMessage,
  }) async {
    final defaultMeaning =
        word.shortMean ?? t.notifications.wordLearning.expandVocabulary;
    var defaultMessage = t.notifications.wordLearning.customLearnMessage;
    defaultMessage = defaultMessage.replaceFirst('{}', word.word);
    defaultMessage = defaultMessage.replaceFirst('{}', defaultMeaning);

    final message = customMessage ?? defaultMessage;

    await NotificationService.scheduleNotification(
      id: _baseNotificationId + 300 + word.id,
      title: t.notifications.wordLearning.customWordReminder,
      body: message,
      scheduledTime: scheduledTime,
      payload: 'custom_word_${word.id}',
    );
  }

  /// Get the count of pending word notifications
  static Future<int> getPendingWordNotificationsCount() async {
    final pendingNotifications =
        await NotificationService.getPendingNotifications();
    return pendingNotifications
        .where((final notification) => notification.id >= _baseNotificationId)
        .length;
  }
}
