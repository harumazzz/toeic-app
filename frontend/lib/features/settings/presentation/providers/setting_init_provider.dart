import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../i18n/strings.g.dart';
import 'setting_provider.dart';
import 'theme_provider.dart';

part 'setting_init_provider.g.dart';

@riverpod
Future<void> settingInit(final Ref ref) async {
  final setting = await ref.read(settingNotifierProvider.future);
  ref.read(themeModeProvider.notifier).themeMode = setting.themeMode;
  await LocaleSettings.setLocaleRaw(setting.language.name);
}
