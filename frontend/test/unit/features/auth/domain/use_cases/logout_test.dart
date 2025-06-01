import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/core/use_cases/use_case.dart';
import 'package:learn/features/auth/domain/repositories/auth_repository.dart';
import 'package:learn/features/auth/domain/use_cases/logout.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LogoutUseCase usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = LogoutUseCase(mockAuthRepository);
  });

  group('LogoutUseCase', () {
    const tParams = NoParams();

    test('should return success when logout is successful', () async {
      // arrange
      const tSuccess = Success();
      when(
        () => mockAuthRepository.logout(),
      ).thenAnswer((_) async => const Right(tSuccess));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Right(tSuccess));
      verify(() => mockAuthRepository.logout());
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return failure when repository logout fails', () async {
      // arrange
      const tFailure = Failure.authenticationFailure(message: 'Logout failed');
      when(
        () => mockAuthRepository.logout(),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockAuthRepository.logout());
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return network failure when network error occurs', () async {
      // arrange
      const tFailure = Failure.networkFailure(message: 'Network error');
      when(
        () => mockAuthRepository.logout(),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockAuthRepository.logout());
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return server failure when server error occurs', () async {
      // arrange
      const tFailure = Failure.serverFailure(message: 'Server error');
      when(
        () => mockAuthRepository.logout(),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockAuthRepository.logout());
      verifyNoMoreInteractions(mockAuthRepository);
    });
  });

  group('NoParams', () {
    test('should create NoParams instance', () {
      // act
      const params = NoParams();

      // assert
      expect(params, isA<NoParams>());
      expect(params.props, isEmpty);
    });

    test('should support equality comparison', () {
      // act
      const params1 = NoParams();
      const params2 = NoParams();

      // assert
      expect(params1, equals(params2));
    });
  });
}
