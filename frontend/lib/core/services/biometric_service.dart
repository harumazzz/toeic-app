import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../i18n/strings.g.dart';

@lazySingleton
class BiometricService {
  BiometricService() : _localAuth = LocalAuthentication();

  final LocalAuthentication _localAuth;
  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Kiểm tra xem thiết bị có hỗ trợ biometric không
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      debugPrint('Error checking device support: $e');
      return false;
    }
  }

  /// Kiểm tra xem có biometric nào được đăng ký trên thiết bị không
  Future<bool> hasAvailableBiometrics() async {
    try {
      final List<BiometricType> availableBiometrics = await _localAuth
          .getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking available biometrics: $e');
      return false;
    }
  }

  /// Lấy danh sách các loại biometric có sẵn
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Kiểm tra xem người dùng đã bật biometric authentication chưa
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      debugPrint('Error checking biometric enabled: $e');
      return false;
    }
  }

  /// Bật/tắt biometric authentication
  Future<void> setBiometricEnabled({
    required final bool enabled,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
    } catch (e) {
      debugPrint('Error setting biometric enabled: $e');
    }
  }

  /// Thực hiện xác thực biometric
  Future<bool> authenticate({
    String? localizedReason,
    final bool useErrorDialogs = true,
    final bool stickyAuth = true,
    final bool skipUserEnabledCheck =
        false, // Thêm parameter để skip check user enabled
  }) async {
    // Use i18n string as default if not provided
    localizedReason ??= t.biometric.authenticateToAccess;
    try {
      debugPrint('[BiometricService] Starting authentication...');

      // Kiểm tra xem thiết bị có hỗ trợ biometric không
      final isSupported = await isDeviceSupported();
      debugPrint('[BiometricService] Device supported: $isSupported');
      if (!isSupported) {
        debugPrint(
          '[BiometricService] Device does not support biometric authentication',
        );
        return false;
      }

      // Kiểm tra xem có biometric nào được đăng ký không
      final hasAvailable = await hasAvailableBiometrics();
      final availableBiometrics = await getAvailableBiometrics();
      debugPrint('[BiometricService] Has available biometrics: $hasAvailable');
      debugPrint(
        '[BiometricService] Available biometrics: $availableBiometrics',
      );
      if (!hasAvailable) {
        debugPrint('[BiometricService] No biometrics available on device');
        return false;
      }

      // Kiểm tra xem người dùng đã bật biometric chưa (chỉ khi không skip)
      if (!skipUserEnabledCheck) {
        final isEnabled = await isBiometricEnabled();
        debugPrint('[BiometricService] User enabled biometric: $isEnabled');
        if (!isEnabled) {
          debugPrint(
            'Biometric authentication is not enabled by user',
          );
          return false;
        }
      }

      debugPrint(
        '[BiometricService] All checks passed, starting authentication...',
      );

      // Thực hiện xác thực
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      debugPrint('[BiometricService] Authentication result: $didAuthenticate');
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint(
        'Platform exception during authentication: ${e.code} - ${e.message}',
      );
      debugPrint('[BiometricService] Platform exception details: ${e.details}');
      return false;
    } catch (e) {
      debugPrint(
        '[BiometricService] Error during biometric authentication: $e',
      );
      return false;
    }
  }

  Future<bool> canUseBiometricAuth() async {
    try {
      final isSupported = await isDeviceSupported();
      final hasAvailable = await hasAvailableBiometrics();
      final isEnabled = await isBiometricEnabled();

      return isSupported && hasAvailable && isEnabled;
    } catch (e) {
      debugPrint('Error checking if can use biometric auth: $e');
      return false;
    }
  }

  /// Lấy tên hiển thị của biometric type
  String getBiometricDisplayName(final BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return t.biometric.biometricTypes.face;
      case BiometricType.fingerprint:
        return t.biometric.biometricTypes.fingerprint;
      case BiometricType.iris:
        return t.biometric.biometricTypes.iris;
      case BiometricType.strong:
        return t.biometric.biometricTypes.strong;
      case BiometricType.weak:
        return t.biometric.biometricTypes.weak;
    }
  }
}
