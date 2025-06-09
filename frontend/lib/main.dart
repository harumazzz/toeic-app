import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

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
      return const _LoadingSettings();
    }
    if (settingInit.hasError) {
      return _ErrorSettings(ref);
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

class _LoadingSettings extends StatelessWidget {
  const _LoadingSettings();

  @override
  Widget build(final BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.indigo.shade50,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Shimmer(
                          color: Colors.blue.shade100,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blue.shade200,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        // Settings icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.settings,
                            size: 32,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Shimmer(
                      duration: const Duration(seconds: 2),
                      color: Colors.grey.shade300,
                      child: Text(
                        context.t.settings.loading,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              left: i > 0 ? 8.0 : 0,
                            ),
                            child: Shimmer(
                              duration: Duration(
                                milliseconds: 800 + (i * 200),
                              ),
                              color: Colors.blue.shade200,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade400,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Shimmer(
                duration: const Duration(seconds: 2, milliseconds: 500),
                color: Colors.white.withValues(alpha: 0.8),
                child: Text(
                  context.t.app.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w300,
                    color: Colors.grey.shade600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ErrorSettings extends StatelessWidget {
  const _ErrorSettings(this.ref);

  final WidgetRef ref;

  @override
  Widget build(final BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.t.settings.error_occurred),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Symbols.refresh),
              label: Text(context.t.settings.retry),
              onPressed: () async => ref.invalidate(settingInitProvider),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<WidgetRef>('ref', ref));
  }
}
