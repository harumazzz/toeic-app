import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/setting.dart';

part 'setting_model.freezed.dart';
part 'setting_model.g.dart';

@freezed
abstract class SettingModel with _$SettingModel {
  const factory SettingModel({
    required final String themeMode,
    required final String language,
    required final bool notificationEnabled,
    @Default(true) final bool wordNotificationEnabled,
    @Default('daily') final String wordNotificationFrequency,
    @Default(9) final int wordNotificationHour,
    @Default(true) final bool reviewNotificationEnabled,
    @Default(true) final bool motivationalNotificationEnabled,
    @Default(true) final bool streakReminderEnabled,
  }) = _SettingModel;

  factory SettingModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$SettingModelFromJson(json);
}

extension SettingModelExtension on SettingModel {
  Setting toEntity() => Setting(
    themeMode: AppThemeMode.values.firstWhere(
      (final e) => e.name == themeMode,
    ),
    language: AppLanguage.values.firstWhere(
      (final e) => e.name == language,
    ),
    notificationEnabled: notificationEnabled,
    wordNotificationEnabled: wordNotificationEnabled,
    wordNotificationFrequency: WordNotificationFrequency.values.firstWhere(
      (final e) => e.name == wordNotificationFrequency,
      orElse: () => WordNotificationFrequency.daily,
    ),
    wordNotificationHour: wordNotificationHour,
    reviewNotificationEnabled: reviewNotificationEnabled,
    motivationalNotificationEnabled: motivationalNotificationEnabled,
    streakReminderEnabled: streakReminderEnabled,
  );
}
