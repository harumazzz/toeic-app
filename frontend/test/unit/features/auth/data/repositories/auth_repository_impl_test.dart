import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/storage/secure_storage_service.dart';
import 'package:learn/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:learn/features/auth/data/models/user_model.dart';
import 'package:learn/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:learn/features/auth/domain/entities/user.dart';
import 'package:mocktail/mocktail.dart';

class MockRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockStorage extends Mock implements SecureStorageService {}

void main() {
  late MockRemoteDataSource remote;
  late MockStorage storage;
  late AuthRepositoryImpl repo;

  setUp(() {
    remote = MockRemoteDataSource();
    storage = MockStorage();
    repo = AuthRepositoryImpl(
      remoteDataSource: remote,
      secureStorageService: storage,
    );
  });

  setUpAll(() {
    registerFallbackValue(const LoginRequest(email: '', password: ''));
  });

  test('login success', () async {
    const userModel = UserModel(id: 1, email: 'a', username: 'b');
    when(() => remote.login(any())).thenAnswer(
      (_) async => const LoginResponse(
        user: userModel,
        accessToken: 'token',
        refreshToken: 'refresh',
        securityConfig: SecurityConfig(
          secretKey: 'key',
          securityLevel: 1,
          wasmEnabled: false,
          webWorkerEnabled: false,
          requiredHeaders: [],
          maxTimestampAge: 0,
        ),
      ),
    );
    when(() => storage.saveAccessToken(any())).thenAnswer((_) async {});
    when(() => storage.saveRefreshToken(any())).thenAnswer((_) async {});
    when(() => storage.saveSecurityKey(any())).thenAnswer((_) async {});
    final result = await repo.login('a', 'b');
    expect(result.isRight, true);
    result.fold(
      ifLeft: (final l) => fail('Expected right, got left: $l'),
      ifRight: (final r) => expect(r, isA<User>()),
    );
  });
}
