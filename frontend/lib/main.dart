import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/loading/presentation/error_settings.dart';
import 'features/loading/presentation/loading_settings.dart';
import 'features/settings/domain/entities/setting.dart';
import 'features/settings/presentation/providers/setting_init_provider.dart';
import 'features/settings/presentation/providers/theme_provider.dart'
    hide ThemeMode;
import 'i18n/strings.g.dart';
import 'injection_container.dart';
import 'shared/routes/app_router.dart';
import 'shared/theme/app_theme.dart';

Future<void> main(
  final List<String> arguments,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(
    ProviderScope(
      child: TranslationProvider(
        child: const Main(),
      ),
    ),
  );
}

class Main extends ConsumerWidget {
  const Main({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final settingInit = ref.watch(settingInitProvider);
    if (settingInit.isLoading) {
      return const LoadingSettings();
    }
    if (settingInit.hasError) {
      return ErrorSettings(ref: ref);
    }
    final appThemeMode = ref.watch(themeModeProvider);
    return DynamicColorBuilder(
      builder:
          (
            final ColorScheme? lightDynamic,
            final ColorScheme? darkDynamic,
          ) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme.copyWith(
              colorScheme: lightDynamic,
            ),
            darkTheme: AppTheme.darkTheme.copyWith(
              colorScheme: darkDynamic,
            ),
            themeMode: _toMaterialThemeMode(appThemeMode),
            routerConfig: AppRouter.router,
          ),
    );
  }
}

ThemeMode _toMaterialThemeMode(final AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.system:
      return ThemeMode.system;
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
  }
}
