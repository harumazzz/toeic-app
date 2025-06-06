import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/setting.dart';

part 'setting_model.freezed.dart';
part 'setting_model.g.dart';

@freezed
sealed class SettingModel with _$SettingModel {
  const factory SettingModel({
    required final String themeMode,
    required final String language,
    required final bool notificationEnabled,
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
  );
}
