import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/speaking/domain/repositories/speaking_repository.dart';
import 'package:learn/features/speaking/domain/use_cases/delete_speaking_session.dart';
import 'package:mocktail/mocktail.dart';

class MockSpeakingRepository extends Mock implements SpeakingRepository {}

void main() {
  late DeleteSpeakingSession usecase;
  late MockSpeakingRepository mockSpeakingRepository;

  setUp(() {
    mockSpeakingRepository = MockSpeakingRepository();
    usecase = DeleteSpeakingSession(mockSpeakingRepository);
  });

  group('DeleteSpeakingSession Use Case', () {
    const tSessionId = 1;
    const tParams = DeleteSpeakingSessionRequest(id: tSessionId);
    const tSuccess = Success();

    test(
      'should delete speaking session from repository when call is successful',
      () async {
        // arrange
        when(
          () => mockSpeakingRepository.deleteSession(
            id: any(named: 'id'),
          ),
        ).thenAnswer((_) async => const Right(tSuccess));

        // act
        final result = await usecase(tParams);

        // assert
        expect(result, const Right(tSuccess));
        verify(
          () => mockSpeakingRepository.deleteSession(id: tSessionId),
        );
        verifyNoMoreInteractions(mockSpeakingRepository);
      },
    );

    test('should return server failure when repository call fails', () async {
      // arrange
      const tFailure = Failure.serverFailure(
        message: 'Failed to delete speaking session',
      );
      when(
        () => mockSpeakingRepository.deleteSession(
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(
        () => mockSpeakingRepository.deleteSession(id: tSessionId),
      );
      verifyNoMoreInteractions(mockSpeakingRepository);
    });

    test('should return network failure when network error occurs', () async {
      // arrange
      const tFailure = Failure.networkFailure(
        message: 'Network connection failed',
      );
      when(
        () => mockSpeakingRepository.deleteSession(
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(
        () => mockSpeakingRepository.deleteSession(id: tSessionId),
      );
      verifyNoMoreInteractions(mockSpeakingRepository);
    });

    test('should handle not found error when session does not exist', () async {
      // arrange
      const tFailure = Failure.serverFailure(
        message: 'Speaking session not found',
      );
      when(
        () => mockSpeakingRepository.deleteSession(
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(
        () => mockSpeakingRepository.deleteSession(id: tSessionId),
      );
      verifyNoMoreInteractions(mockSpeakingRepository);
    });

    test('should handle different session IDs correctly', () async {
      // arrange
      const tDifferentSessionId = 999;
      const tDifferentParams = DeleteSpeakingSessionRequest(
        id: tDifferentSessionId,
      );

      when(
        () => mockSpeakingRepository.deleteSession(
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async => const Right(tSuccess));

      // act
      final result = await usecase(tDifferentParams);

      // assert
      expect(result, const Right(tSuccess));
      verify(
        () => mockSpeakingRepository.deleteSession(
          id: tDifferentSessionId,
        ),
      );
      verifyNoMoreInteractions(mockSpeakingRepository);
    });
  });

  group('DeleteSpeakingSessionRequest', () {
    test('should create request with correct id', () {
      // arrange
      const tSessionId = 123;

      // act
      const request = DeleteSpeakingSessionRequest(id: tSessionId);

      // assert
      expect(request.id, tSessionId);
    });

    test('should support copyWith', () {
      // arrange
      const tOriginalId = 123;
      const tNewId = 456;
      const originalRequest = DeleteSpeakingSessionRequest(
        id: tOriginalId,
      );

      // act
      final newRequest = originalRequest.copyWith(id: tNewId);

      // assert
      expect(originalRequest.id, tOriginalId);
      expect(newRequest.id, tNewId);
    });

    test('should support equality comparison', () {
      // arrange
      const tSessionId = 123;
      const request1 = DeleteSpeakingSessionRequest(id: tSessionId);
      const request2 = DeleteSpeakingSessionRequest(id: tSessionId);
      const request3 = DeleteSpeakingSessionRequest(id: 456);

      // assert
      expect(request1, equals(request2));
      expect(request1, isNot(equals(request3)));
    });
  });
}
