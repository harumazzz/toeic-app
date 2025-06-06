import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../i18n/strings.g.dart';
import '../../domain/entities/setting.dart';

part 'theme_provider.g.dart';

@riverpod
class ThemeMode extends _$ThemeMode {
  @override
  AppThemeMode build() => AppThemeMode.system;

  set themeMode(final AppThemeMode mode) => state = mode;

  AppThemeMode get themeMode => state;
}

String getTitle(
  final AppThemeMode state,
  final Translations translation,
) => switch (state) {
  AppThemeMode.system => translation.settings.theme_system,
  AppThemeMode.light => translation.settings.theme_light,
  AppThemeMode.dark => translation.settings.theme_dark,
};
