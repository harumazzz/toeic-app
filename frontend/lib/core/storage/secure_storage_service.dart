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

  Future<void> saveAccessToken(
    final String token,
  ) async => _secureStorage.write(
    key: accessTokenKey,
    value: token,
  );

  Future<void> saveRefreshToken(
    final String token,
  ) async => _secureStorage.write(
    key: refreshTokenKey,
    value: token,
  );

  Future<void> saveUserId(final String userId) async => _secureStorage.write(
    key: userIdKey,
    value: userId,
  );

  Future<String?> getAccessToken() async => _secureStorage.read(
    key: accessTokenKey,
  );

  Future<String?> getRefreshToken() async => _secureStorage.read(
    key: refreshTokenKey,
  );

  Future<String?> getUserId() async => _secureStorage.read(key: userIdKey);

  Future<void> deleteAccessToken() async => _secureStorage.delete(
    key: accessTokenKey,
  );

  Future<void> deleteRefreshToken() async => _secureStorage.delete(
    key: refreshTokenKey,
  );

  Future<void> deleteUserId() async => _secureStorage.delete(
    key: userIdKey,
  );

  Future<void> clearAllTokens() async {
    await deleteAccessToken();
    await deleteRefreshToken();
    await deleteUserId();
  }
}
