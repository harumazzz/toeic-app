import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../shared/routes/app_router.dart';
import '../providers/setting_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/language_setting_tile.dart';
import '../widgets/notification_setting_tile.dart';
import '../widgets/theme_setting_tile.dart';
import '../widgets/word_notification_settings.dart';

class SettingScreen extends HookConsumerWidget {
  const SettingScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final settingAsync = ref.watch(settingNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.settings.title),
      ),
      body: settingAsync.when(
        loading: () => const _ShimmerSettings(),
        error: (final e, final st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.t.settings.error_occurred),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Symbols.refresh),
                label: Text(context.t.settings.retry),
                onPressed: () => ref.invalidate(settingNotifierProvider),
              ),
            ],
          ),
        ),
        data: (final setting) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t.settings.kDefault,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ThemeSettingTile(
                      value: setting.themeMode,
                      onChanged: (final mode) async {
                        ref.read(themeModeProvider.notifier).themeMode = mode;
                        await ref
                            .read(settingNotifierProvider.notifier)
                            .updateSetting(
                              setting.copyWith(themeMode: mode),
                            );
                      },
                    ),
                    const SizedBox(height: 8),
                    LanguageSettingTile(
                      value: setting.language,
                      onChanged: (final lang) async {
                        await LocaleSettings.setLocaleRaw(lang.name);
                        await ref
                            .read(settingNotifierProvider.notifier)
                            .updateSetting(
                              setting.copyWith(language: lang),
                            );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t.settings.application,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    NotificationSettingTile(
                      value: setting.notificationEnabled,
                      onChanged: (final val) async {
                        await ref
                            .read(settingNotifierProvider.notifier)
                            .updateSetting(
                              setting.copyWith(notificationEnabled: val),
                            );
                      },
                    ),
                    const SizedBox(height: 16), // Word notification settings
                    if (setting.notificationEnabled) ...[
                      WordNotificationSettingTile(
                        value: setting.wordNotificationEnabled,
                        isMainNotificationEnabled: setting.notificationEnabled,
                        onChanged: (final val) async {
                          await ref
                              .read(settingNotifierProvider.notifier)
                              .updateSetting(
                                setting.copyWith(wordNotificationEnabled: val),
                              );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.only(top: 20),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t.biometric.security,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Icon(
                        Symbols.fingerprint,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: Text(context.t.biometric.title),
                      subtitle: Text(context.t.biometric.securitySubtitle),
                      trailing: Icon(
                        Symbols.chevron_right,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      onTap: () async {
                        await const BiometricSettingsRoute().push(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerSettings extends StatelessWidget {
  const _ShimmerSettings();
  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shimmerColor = colorScheme.brightness == Brightness.light
        ? Colors.grey[300]!
        : Colors.grey[700]!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Shimmer(
          duration: const Duration(seconds: 2),
          color: shimmerColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(
                2,
                (final i) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 24,
                            width: 180,
                            color: shimmerColor,
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(
                            2,
                            (final j) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Container(height: 56, color: shimmerColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
