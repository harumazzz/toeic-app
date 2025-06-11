import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SecureStorageService {
  const SecureStorageService({
    required final FlutterSecureStorage secureStorage,
  }) : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;

  static const String accessTokenKey = 'access_token';

  static const String refreshTokenKey = 'refresh_token';

  static const String userIdKey = 'user_id';
  static const String refreshTokenExpiryKey = 'refresh_token_expiry';

  static const String securityKey = 'security_key';

  Future<void> saveAccessToken(
    final String token,
  ) async => _secureStorage.write(
    key: accessTokenKey,
    value: token,
  );

  Future<void> saveRefreshToken(
    final String token,
  ) async {
    await _secureStorage.write(
      key: refreshTokenKey,
      value: token,
    );
    final expired = DateTime.now().add(const Duration(days: 7));
    await _secureStorage.write(
      key: refreshTokenExpiryKey,
      value: expired.toIso8601String(),
    );
  }

  Future<void> saveUserId(final String userId) async => _secureStorage.write(
    key: userIdKey,
    value: userId,
  );

  Future<void> saveSecurityKey(final String key) async => _secureStorage.write(
    key: securityKey,
    value: key,
  );

  Future<String?> getAccessToken() async => _secureStorage.read(
    key: accessTokenKey,
  );

  Future<String?> getRefreshToken() async => _secureStorage.read(
    key: refreshTokenKey,
  );

  Future<DateTime?> getRefreshTokenExpiry() async {
    final expiryString = await _secureStorage.read(
      key: refreshTokenExpiryKey,
    );
    if (expiryString == null) {
      return null;
    }
    try {
      return DateTime.parse(expiryString);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isExpired() async {
    final expiry = await getRefreshTokenExpiry();
    if (expiry == null) {
      return true;
    }
    return DateTime.now().isAfter(expiry);
  }

  Future<String?> getUserId() async => _secureStorage.read(key: userIdKey);

  Future<String?> getSecurityKey() async => _secureStorage.read(
    key: securityKey,
  );

  Future<void> deleteAccessToken() async => _secureStorage.delete(
    key: accessTokenKey,
  );

  Future<void> deleteRefreshToken() async {
    await _secureStorage.delete(key: refreshTokenKey);
    await _secureStorage.delete(key: refreshTokenExpiryKey);
  }

  Future<void> deleteUserId() async => _secureStorage.delete(
    key: userIdKey,
  );

  Future<void> deleteSecurityKey() async => _secureStorage.delete(
    key: securityKey,
  );

  Future<void> clearAllTokens() async {
    await deleteAccessToken();
    await deleteRefreshToken();
    await deleteUserId();
    await deleteSecurityKey();
  }
}
