import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/auth/domain/entities/user.dart';
import 'package:learn/features/auth/domain/repositories/auth_repository.dart';
import 'package:learn/features/auth/domain/use_cases/login_user.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUser usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = LoginUser(mockAuthRepository);
  });

  group('LoginUser', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tUser = User(
      id: 1,
      email: tEmail,
      username: 'testuser',
    );
    const tParams = LoginParams(email: tEmail, password: tPassword);

    test(
      'should get user from the repository when login is successful',
      () async {
        // arrange
        when(
          () => mockAuthRepository.login(any(), any()),
        ).thenAnswer((_) async => const Right(tUser));

        // act
        final result = await usecase(tParams);

        // assert
        expect(result, const Right(tUser));
        verify(() => mockAuthRepository.login(tEmail, tPassword));
        verifyNoMoreInteractions(mockAuthRepository);
      },
    );

    test('should return failure when repository login fails', () async {
      // arrange
      const tFailure = Failure.authenticationFailure(
        message: 'Invalid credentials',
      );
      when(
        () => mockAuthRepository.login(any(), any()),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockAuthRepository.login(tEmail, tPassword));
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return network failure when network error occurs', () async {
      // arrange
      const tFailure = Failure.networkFailure(message: 'Network error');
      when(
        () => mockAuthRepository.login(any(), any()),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockAuthRepository.login(tEmail, tPassword));
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return server failure when server error occurs', () async {
      // arrange
      const tFailure = Failure.serverFailure(message: 'Server error');
      when(
        () => mockAuthRepository.login(any(), any()),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockAuthRepository.login(tEmail, tPassword));
      verifyNoMoreInteractions(mockAuthRepository);
    });
  });

  group('LoginParams', () {
    test('should create LoginParams with correct values', () {
      // arrange
      const tEmail = 'test@example.com';
      const tPassword = 'password123';

      // act
      const params = LoginParams(email: tEmail, password: tPassword);

      // assert
      expect(params.email, tEmail);
      expect(params.password, tPassword);
    });

    test('should support equality comparison', () {
      // arrange
      const tEmail = 'test@example.com';
      const tPassword = 'password123';

      // act
      const params1 = LoginParams(email: tEmail, password: tPassword);
      const params2 = LoginParams(email: tEmail, password: tPassword);

      // assert
      expect(params1, equals(params2));
    });
  });
}
