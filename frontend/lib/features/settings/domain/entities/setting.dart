import 'package:freezed_annotation/freezed_annotation.dart';

part 'setting.freezed.dart';

enum AppThemeMode {
  system,
  light,
  dark,
}

enum AppLanguage {
  en,
  vi,
}

enum WordNotificationFrequency {
  daily,
  twiceDaily,
  threeTimesDaily,
  hourly,
}

@freezed
abstract class Setting with _$Setting {
  const factory Setting({
    required final AppThemeMode themeMode,
    required final AppLanguage language,
    required final bool notificationEnabled,
    @Default(true) final bool wordNotificationEnabled,
    @Default(WordNotificationFrequency.daily)
    final WordNotificationFrequency wordNotificationFrequency,
    @Default(9) final int wordNotificationHour,
    @Default(true) final bool reviewNotificationEnabled,
    @Default(true) final bool motivationalNotificationEnabled,
    @Default(true) final bool streakReminderEnabled,
  }) = _Setting;
}
