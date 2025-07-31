import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../injection_container.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(final BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('subtitle', subtitle))
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(ColorProperty('iconColor', iconColor));
  }
}

class BiometricSettingsScreen extends HookConsumerWidget {
  const BiometricSettingsScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final biometricService = InjectionContainer.get<BiometricService>();
    final isSupported = useState<bool?>(null);
    final hasAvailable = useState<bool?>(null);
    final isEnabled = useState<bool?>(null);
    final availableBiometrics = useState<List<BiometricType>>([]);
    final isLoading = useState(false);

    // Khởi tạo thông tin biometric
    useEffect(() {
      Future<void> loadBiometricInfo() async {
        final supported = await biometricService.isDeviceSupported();
        final available = await biometricService.hasAvailableBiometrics();
        final enabled = await biometricService.isBiometricEnabled();
        final biometrics = await biometricService.getAvailableBiometrics();

        isSupported.value = supported;
        hasAvailable.value = available;
        isEnabled.value = enabled;
        availableBiometrics.value = biometrics;
      }

      loadBiometricInfo();
      return null;
    }, []);

    Future<void> handleBiometricToggle({
      required final bool value,
    }) async {
      if (isLoading.value) {
        return;
      }
      isLoading.value = true;
      try {
        if (value) {
          final authenticated = await biometricService.authenticate(
            localizedReason: t.biometric.authenticateToEnable,
            skipUserEnabledCheck: true,
          );

          if (authenticated) {
            await biometricService.setBiometricEnabled(
              enabled: true,
            );
            isEnabled.value = true;
            if (context.mounted) {
              ToastService.success(
                context: context,
                message: t.biometric.biometricEnabled,
              );
            }
          } else {
            if (context.mounted) {
              ToastService.error(
                context: context,
                message: t.biometric.authenticationFailed,
              );
            }
          }
        } else {
          await biometricService.setBiometricEnabled(
            enabled: false,
          );
          isEnabled.value = false;
          if (context.mounted) {
            ToastService.success(
              context: context,
              message: t.biometric.biometricDisabled,
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ToastService.error(
            context: context,
            message: t.biometric.settingChangeError,
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.biometric.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Symbols.fingerprint,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.biometric.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.biometric.enableBiometricSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Status cards
              if (isSupported.value != null) ...[
                Builder(
                  builder: (final context) {
                    final colorScheme = Theme.of(context).colorScheme;
                    return StatusCard(
                      title: t.biometric.deviceSupport,
                      subtitle: isSupported.value!
                          ? t.biometric.deviceSupportedMessage
                          : t.biometric.deviceNotSupportedMessage,
                      icon: isSupported.value!
                          ? Symbols.check_circle
                          : Symbols.cancel,
                      iconColor: isSupported.value!
                          ? colorScheme.tertiary
                          : colorScheme.error,
                    );
                  },
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (final context) {
                    final colorScheme = Theme.of(context).colorScheme;
                    return StatusCard(
                      title: t.biometric.biometricsAvailable,
                      subtitle: hasAvailable.value!
                          ? t.biometric.biometricsAvailableMessage
                          : t.biometric.biometricsNotAvailableMessage,
                      icon: hasAvailable.value!
                          ? Symbols.check_circle
                          : Symbols.cancel,
                      iconColor: hasAvailable.value!
                          ? colorScheme.tertiary
                          : colorScheme.error,
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],

              // Available biometrics
              if (availableBiometrics.value.isNotEmpty) ...[
                Text(
                  t.biometric.availableMethods,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...availableBiometrics.value.map(
                  (final type) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          _getBiometricIcon(type),
                          size: 24,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          biometricService.getBiometricDisplayName(type),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (isSupported.value != null &&
                  isSupported.value! &&
                  hasAvailable.value != null &&
                  hasAvailable.value!) ...[
                Card(
                  child: ListTile(
                    title: Text(t.biometric.enableBiometric),
                    subtitle: Text(
                      t.biometric.enableBiometricSubtitle,
                    ),
                    leading: Icon(
                      Symbols.security,
                      color: Theme.of(context).primaryColor,
                    ),
                    trailing: isLoading.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Switch(
                            value: isEnabled.value ?? false,
                            onChanged: (final value) =>
                                handleBiometricToggle(value: value),
                          ),
                  ),
                ),
              ],

              // Warning message
              if (isSupported.value == false ||
                  hasAvailable.value == false) ...[
                const SizedBox(height: 24),
                Builder(
                  builder: (final context) {
                    final colorScheme = Theme.of(context).colorScheme;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Symbols.warning,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isSupported.value == false
                                  ? t.biometric.deviceNotSupportedMessage
                                  : t.biometric.setupInstructions,
                              style: TextStyle(
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getBiometricIcon(final BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return Symbols.face_unlock;
      case BiometricType.fingerprint:
        return Symbols.fingerprint;
      case BiometricType.iris:
        return Symbols.visibility;
      case BiometricType.strong:
      case BiometricType.weak:
        return Symbols.security;
    }
  }
}
