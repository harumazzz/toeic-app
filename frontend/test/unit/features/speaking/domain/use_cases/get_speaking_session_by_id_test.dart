import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/speaking/domain/entities/speaking.dart';
import 'package:learn/features/speaking/domain/repositories/speaking_repository.dart';
import 'package:learn/features/speaking/domain/use_cases/get_speaking_session_by_id.dart';
import 'package:mocktail/mocktail.dart';

class MockSpeakingRepository extends Mock implements SpeakingRepository {}

void main() {
  late GetSpeakingSessionById usecase;
  late MockSpeakingRepository mockSpeakingRepository;

  setUp(() {
    mockSpeakingRepository = MockSpeakingRepository();
    usecase = GetSpeakingSessionById(mockSpeakingRepository);
  });

  group('GetSpeakingSessionById Use Case', () {
    const tSessionId = 1;
    const tParams = GetSpeakingSessionByIdRequest(id: tSessionId);
    final tSpeakingSession = Speaking(
      id: tSessionId,
      userId: 123,
      sessionTopic: 'TOEIC Speaking Practice',
      startTime: DateTime(2023, 1, 1, 10),
      endTime: DateTime(2023, 1, 1, 11),
      updatedAt: DateTime(2023, 1, 1, 11),
    );

    test(
      'should get speaking session from repository when call is successful',
      () async {
        // arrange
        when(
          () => mockSpeakingRepository.getSessionById(
            id: any(named: 'id'),
          ),
        ).thenAnswer((_) async => Right(tSpeakingSession));

        // act
        final result = await usecase(tParams);

        // assert
        expect(result, Right(tSpeakingSession));
        verify(
          () => mockSpeakingRepository.getSessionById(id: tSessionId),
        );
        verifyNoMoreInteractions(mockSpeakingRepository);
      },
    );

    test('should return server failure when repository call fails', () async {
      // arrange
      const tFailure = Failure.serverFailure(
        message: 'Speaking session not found',
      );
      when(
        () => mockSpeakingRepository.getSessionById(
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(
        () => mockSpeakingRepository.getSessionById(id: tSessionId),
      );
      verifyNoMoreInteractions(mockSpeakingRepository);
    });

    test('should return network failure when network error occurs', () async {
      // arrange
      const tFailure = Failure.networkFailure(
        message: 'Network connection failed',
      );
      when(
        () => mockSpeakingRepository.getSessionById(
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(
        () => mockSpeakingRepository.getSessionById(id: tSessionId),
      );
      verifyNoMoreInteractions(mockSpeakingRepository);
    });

    test('should handle different session IDs correctly', () async {
      // arrange
      const tDifferentSessionId = 999;
      const tDifferentParams = GetSpeakingSessionByIdRequest(
        id: tDifferentSessionId,
      );
      final tDifferentSession = Speaking(
        id: tDifferentSessionId,
        userId: 456,
        sessionTopic: 'Advanced TOEIC Speaking',
        startTime: DateTime(2023, 1, 3, 9),
        endTime: DateTime(2023, 1, 3, 10, 30),
        updatedAt: DateTime(2023, 1, 3, 10, 30),
      );

      when(
        () => mockSpeakingRepository.getSessionById(
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async => Right(tDifferentSession));

      // act
      final result = await usecase(tDifferentParams);

      // assert
      expect(result, Right(tDifferentSession));
      verify(
        () => mockSpeakingRepository.getSessionById(
          id: tDifferentSessionId,
        ),
      );
      verifyNoMoreInteractions(mockSpeakingRepository);
    });
  });

  group('GetSpeakingSessionByIdRequest', () {
    test('should create request with correct id', () {
      // arrange
      const tSessionId = 123;

      // act
      const request = GetSpeakingSessionByIdRequest(id: tSessionId);

      // assert
      expect(request.id, tSessionId);
    });

    test('should support copyWith', () {
      // arrange
      const tOriginalId = 123;
      const tNewId = 456;
      const originalRequest = GetSpeakingSessionByIdRequest(
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
      const request1 = GetSpeakingSessionByIdRequest(id: tSessionId);
      const request2 = GetSpeakingSessionByIdRequest(id: tSessionId);
      const request3 = GetSpeakingSessionByIdRequest(id: 456);

      // assert
      expect(request1, equals(request2));
      expect(request1, isNot(equals(request3)));
    });
  });
}
