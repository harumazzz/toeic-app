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

@freezed
sealed class Setting with _$Setting {
  const factory Setting({
    required final AppThemeMode themeMode,
    required final AppLanguage language,
    required final bool notificationEnabled,
  }) = _Setting;
}
