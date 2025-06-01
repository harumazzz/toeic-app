import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/auth/domain/entities/user.dart';
import 'package:learn/features/auth/domain/repositories/auth_repository.dart';
import 'package:learn/features/auth/domain/use_cases/register_user.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late RegisterUser usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = RegisterUser(mockAuthRepository);
  });

  group('RegisterUser', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tUsername = 'testuser';
    const tUser = User(
      id: 1,
      email: tEmail,
      username: tUsername,
    );
    const tParams = RegisterParams(
      email: tEmail,
      password: tPassword,
      username: tUsername,
    );

    test(
      'should get user from the repository when registration is successful',
      () async {
        // arrange
        when(
          () => mockAuthRepository.register(any(), any(), any()),
        ).thenAnswer((_) async => const Right(tUser));

        // act
        final result = await usecase(tParams);

        // assert
        expect(result, const Right(tUser));
        verify(() => mockAuthRepository.register(tEmail, tPassword, tUsername));
        verifyNoMoreInteractions(mockAuthRepository);
      },
    );

    test('should return failure when repository registration fails', () async {
      // arrange
      const tFailure = Failure.authenticationFailure(
        message: 'Invalid registration data',
      );
      when(
        () => mockAuthRepository.register(any(), any(), any()),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockAuthRepository.register(tEmail, tPassword, tUsername));
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return network failure when network error occurs', () async {
      // arrange
      const tFailure = Failure.networkFailure(message: 'Network error');
      when(
        () => mockAuthRepository.register(any(), any(), any()),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockAuthRepository.register(tEmail, tPassword, tUsername));
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return server failure when server error occurs', () async {
      // arrange
      const tFailure = Failure.serverFailure(message: 'Server error');
      when(
        () => mockAuthRepository.register(any(), any(), any()),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockAuthRepository.register(tEmail, tPassword, tUsername));
      verifyNoMoreInteractions(mockAuthRepository);
    });
  });

  group('RegisterParams', () {
    test('should create RegisterParams with correct values', () {
      // arrange
      const tEmail = 'test@example.com';
      const tPassword = 'password123';
      const tUsername = 'testuser';

      // act
      const params = RegisterParams(
        email: tEmail,
        password: tPassword,
        username: tUsername,
      );

      // assert
      expect(params.email, tEmail);
      expect(params.password, tPassword);
      expect(params.username, tUsername);
    });

    test('should support equality comparison', () {
      // arrange
      const tEmail = 'test@example.com';
      const tPassword = 'password123';
      const tUsername = 'testuser';

      // act
      const params1 = RegisterParams(
        email: tEmail,
        password: tPassword,
        username: tUsername,
      );
      const params2 = RegisterParams(
        email: tEmail,
        password: tPassword,
        username: tUsername,
      );

      // assert
      expect(params1, equals(params2));
    });
  });
}
