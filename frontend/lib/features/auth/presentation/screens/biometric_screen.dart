import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../injection_container.dart';
import '../../../../shared/routes/app_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_card.dart';

class BiometricScreen extends HookConsumerWidget {
  const BiometricScreen({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final biometricService = InjectionContainer.get<BiometricService>();
    final isAuthenticating = useState(false);
    final availableBiometrics = useState<List<BiometricType>>([]);

    // Lấy thông tin biometric khi màn hình được khởi tạo
    useEffect(() {
      Future<void> initBiometrics() async {
        final biometrics = await biometricService.getAvailableBiometrics();
        availableBiometrics.value = biometrics;
      }

      initBiometrics();
      return null;
    }, []);

    // Lắng nghe auth state
    ref.listen(
      authControllerProvider,
      (final previous, final next) {
        if (next is AuthAuthenticated) {
          const HomeRoute().go(context);
        } else if (next is AuthError) {
          ToastService.error(
            context: context,
            message: next.message,
          );
          // Nếu có lỗi, chuyển về màn hình login
          const LoginRoute().go(context);
        }
      },
    );

    Future<void> handleBiometricAuth() async {
      if (isAuthenticating.value) {
        return;
      }

      debugPrint('[BiometricScreen] Starting biometric authentication...');
      isAuthenticating.value = true;

      try {
        // Debug: Kiểm tra trạng thái trước khi xác thực
        final isSupported = await biometricService.isDeviceSupported();
        final hasAvailable = await biometricService.hasAvailableBiometrics();
        final isEnabled = await biometricService.isBiometricEnabled();
        final biometrics = await biometricService.getAvailableBiometrics();

        debugPrint('[BiometricScreen] Device supported: $isSupported');
        debugPrint('[BiometricScreen] Has available: $hasAvailable');
        debugPrint('[BiometricScreen] User enabled: $isEnabled');
        debugPrint('[BiometricScreen] Available biometrics: $biometrics');

        final authenticated = await biometricService.authenticate(
          localizedReason: t.biometric.authenticateToAccess,
        );

        debugPrint('[BiometricScreen] Authentication result: $authenticated');

        if (authenticated) {
          debugPrint(
            '[BiometricScreen] Authentication successful, getting user info...',
          );
          // Nếu xác thực thành công, lấy thông tin user từ token
          await ref.read(authControllerProvider.notifier).getCurrentUser();
        } else {
          debugPrint(
            '[BiometricScreen] Authentication failed, redirecting to login...',
          );
          if (context.mounted) {
            ToastService.error(
              context: context,
              message: t.biometric.authenticationFailed,
            );
            const LoginRoute().go(context);
          }
        }
      } catch (e, stackTrace) {
        debugPrint('[BiometricScreen] Exception during authentication: $e');
        debugPrint('[BiometricScreen] Stack trace: $stackTrace');
        if (context.mounted) {
          ToastService.error(
            context: context,
            message: '${t.biometric.authenticationError}: $e',
          );
          const LoginRoute().go(context);
        }
      } finally {
        isAuthenticating.value = false;
        debugPrint('[BiometricScreen] Authentication process completed');
      }
    }

    void handleLoginRedirect() {
      const LoginRoute().go(context);
    }

    return Scaffold(
      body: AuthCard(
        children: [
          // Header
          const SizedBox(height: 40),
          Icon(
            Symbols.fingerprint,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            t.biometric.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            t.biometric.subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),

          // Available biometrics info
          if (availableBiometrics.value.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              t.biometric.availableMethods,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...availableBiometrics.value.map(
              (final type) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getBiometricIcon(type),
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      biometricService.getBiometricDisplayName(type),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),

          // Authenticate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isAuthenticating.value ? null : handleBiometricAuth,
              icon: isAuthenticating.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Symbols.fingerprint),
              label: Text(
                isAuthenticating.value
                    ? t.biometric.authenticating
                    : t.biometric.authenticateNow,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Login with password button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: handleLoginRedirect,
              child: Text(
                t.biometric.loginWithPassword,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
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
