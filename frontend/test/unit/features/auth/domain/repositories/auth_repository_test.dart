import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/auth/domain/entities/user.dart';
import 'package:learn/features/auth/domain/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('AuthRepository', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tUsername = 'testuser';
    const tUser = User(
      id: '1',
      email: tEmail,
      username: tUsername,
    );

    group('login', () {
      test('should return User when login is successful', () async {
        // arrange
        when(
          () => mockAuthRepository.login(any(), any()),
        ).thenAnswer((_) async => const Right(tUser));

        // act
        final result = await mockAuthRepository.login(tEmail, tPassword);

        // assert
        expect(result, const Right(tUser));
        verify(() => mockAuthRepository.login(tEmail, tPassword));
        verifyNoMoreInteractions(mockAuthRepository);
      });

      test(
        'should return AuthenticationFailure when login fails',
        () async {
          // arrange
          const tFailure = Failure.authenticationFailure(
            message: 'Invalid credentials',
          );
          when(
            () => mockAuthRepository.login(any(), any()),
          ).thenAnswer((_) async => const Left(tFailure));

          // act
          final result = await mockAuthRepository.login(tEmail, tPassword);

          // assert
          expect(result, const Left(tFailure));
          verify(() => mockAuthRepository.login(tEmail, tPassword));
          verifyNoMoreInteractions(mockAuthRepository);
        },
      );

      test('should return NetworkFailure when network error occurs', () async {
        // arrange
        const tFailure = Failure.networkFailure(message: 'Network error');
        when(
          () => mockAuthRepository.login(any(), any()),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await mockAuthRepository.login(tEmail, tPassword);

        // assert
        expect(result, const Left(tFailure));
        verify(() => mockAuthRepository.login(tEmail, tPassword));
        verifyNoMoreInteractions(mockAuthRepository);
      });

      test('should return ServerFailure when server error occurs', () async {
        // arrange
        const tFailure = Failure.serverFailure(message: 'Server error');
        when(
          () => mockAuthRepository.login(any(), any()),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await mockAuthRepository.login(tEmail, tPassword);

        // assert
        expect(result, const Left(tFailure));
        verify(() => mockAuthRepository.login(tEmail, tPassword));
        verifyNoMoreInteractions(mockAuthRepository);
      });
    });

    group('register', () {
      test('should return User when registration is successful', () async {
        // arrange
        when(
          () => mockAuthRepository.register(any(), any(), any()),
        ).thenAnswer((_) async => const Right(tUser));

        // act
        final result = await mockAuthRepository.register(
          tEmail,
          tPassword,
          tUsername,
        );

        // assert
        expect(result, const Right(tUser));
        verify(() => mockAuthRepository.register(tEmail, tPassword, tUsername));
        verifyNoMoreInteractions(mockAuthRepository);
      });

      test(
        'should return AuthenticationFailure when registration fail',
        () async {
          // arrange
          const tFailure = Failure.authenticationFailure(
            message: 'Invalid registration data',
          );
          when(
            () => mockAuthRepository.register(any(), any(), any()),
          ).thenAnswer((_) async => const Left(tFailure));

          // act
          final result = await mockAuthRepository.register(
            tEmail,
            tPassword,
            tUsername,
          );

          // assert
          expect(result, const Left(tFailure));
          verify(
            () => mockAuthRepository.register(tEmail, tPassword, tUsername),
          );
          verifyNoMoreInteractions(mockAuthRepository);
        },
      );

      test(
        'should return fail when network error occurs during registration',
        () async {
          // arrange
          const tFailure = Failure.networkFailure(message: 'Network error');
          when(
            () => mockAuthRepository.register(any(), any(), any()),
          ).thenAnswer((_) async => const Left(tFailure));

          // act
          final result = await mockAuthRepository.register(
            tEmail,
            tPassword,
            tUsername,
          );

          // assert
          expect(result, const Left(tFailure));
          verify(
            () => mockAuthRepository.register(tEmail, tPassword, tUsername),
          );
          verifyNoMoreInteractions(mockAuthRepository);
        },
      );

      test(
        'should return fail when server error occurs during registration',
        () async {
          // arrange
          const tFailure = Failure.serverFailure(message: 'Server error');
          when(
            () => mockAuthRepository.register(any(), any(), any()),
          ).thenAnswer((_) async => const Left(tFailure));

          // act
          final result = await mockAuthRepository.register(
            tEmail,
            tPassword,
            tUsername,
          );

          // assert
          expect(result, const Left(tFailure));
          verify(
            () => mockAuthRepository.register(tEmail, tPassword, tUsername),
          );
          verifyNoMoreInteractions(mockAuthRepository);
        },
      );
    });

    group('logout', () {
      test('should return Success when logout is successful', () async {
        // arrange
        const tSuccess = Success();
        when(
          () => mockAuthRepository.logout(),
        ).thenAnswer((_) async => const Right(tSuccess));

        // act
        final result = await mockAuthRepository.logout();

        // assert
        expect(result, const Right(tSuccess));
        verify(() => mockAuthRepository.logout());
        verifyNoMoreInteractions(mockAuthRepository);
      });

      test('should return Failure when logout fails', () async {
        // arrange
        const tFailure = Failure.authenticationFailure(
          message: 'Logout failed',
        );
        when(
          () => mockAuthRepository.logout(),
        ).thenAnswer((_) async => const Left(tFailure));

        // act
        final result = await mockAuthRepository.logout();

        // assert
        expect(result, const Left(tFailure));
        verify(() => mockAuthRepository.logout());
        verifyNoMoreInteractions(mockAuthRepository);
      });
    });
  });
}
