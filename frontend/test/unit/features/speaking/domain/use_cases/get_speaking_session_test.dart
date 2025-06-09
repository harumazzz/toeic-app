import 'package:dart_either/dart_either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/speaking/domain/entities/speaking.dart';
import 'package:learn/features/speaking/domain/repositories/speaking_repository.dart';
import 'package:learn/features/speaking/domain/use_cases/get_speaking_session.dart';
import 'package:mocktail/mocktail.dart';

class MockSpeakingRepository extends Mock implements SpeakingRepository {}

void main() {
  late GetSpeakingSession usecase;
  late MockSpeakingRepository mockSpeakingRepository;

  setUp(() {
    mockSpeakingRepository = MockSpeakingRepository();
    usecase = GetSpeakingSession(mockSpeakingRepository);
  });

  group('GetSpeakingSession Use Case', () {
    const tUserId = 1;
    const tParams = GetSpeakingSessionRequest(userId: tUserId);
    final tSpeakingSessions = [
      Speaking(
        id: 1,
        userId: tUserId,
        sessionTopic: 'TOEIC Speaking Practice',
        startTime: DateTime(2023, 1, 1, 10),
        endTime: DateTime(2023, 1, 1, 11),
        updatedAt: DateTime(2023, 1, 1, 11),
      ),
      Speaking(
        id: 2,
        userId: tUserId,
        sessionTopic: 'Business English Speaking',
        startTime: DateTime(2023, 1, 2, 14),
        endTime: DateTime(2023, 1, 2, 15),
        updatedAt: DateTime(2023, 1, 2, 15),
      ),
    ];

    test(
      'should get speaking sessions from repository when call is successful',
      () async {
        // arrange
        when(
          () => mockSpeakingRepository.getSpeakingSessions(
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => Right(tSpeakingSessions));

        // act
        final result = await usecase(tParams);

        // assert
        expect(result, Right(tSpeakingSessions));
        verify(
          () => mockSpeakingRepository.getSpeakingSessions(userId: tUserId),
        );
        verifyNoMoreInteractions(mockSpeakingRepository);
      },
    );

    test('should return empty list when no sessions found', () async {
      // arrange
      const tEmptySessions = <Speaking>[];
      when(
        () => mockSpeakingRepository.getSpeakingSessions(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => const Right(tEmptySessions));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Right(tEmptySessions));
      verify(
        () => mockSpeakingRepository.getSpeakingSessions(userId: tUserId),
      );
      verifyNoMoreInteractions(mockSpeakingRepository);
    });

    test('should return server failure when repository call fails', () async {
      // arrange
      const tFailure = Failure.serverFailure(
        message: 'Speaking sessions not found',
      );
      when(
        () => mockSpeakingRepository.getSpeakingSessions(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(
        () => mockSpeakingRepository.getSpeakingSessions(userId: tUserId),
      );
      verifyNoMoreInteractions(mockSpeakingRepository);
    });

    test('should return network failure when network error occurs', () async {
      // arrange
      const tFailure = Failure.networkFailure(
        message: 'Network connection failed',
      );
      when(
        () => mockSpeakingRepository.getSpeakingSessions(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(tParams);

      // assert
      expect(result, const Left(tFailure));
      verify(
        () => mockSpeakingRepository.getSpeakingSessions(userId: tUserId),
      );
      verifyNoMoreInteractions(mockSpeakingRepository);
    });
  });

  group('GetSpeakingSessionRequest', () {
    test('should create request with correct userId', () {
      // arrange
      const tUserId = 123;

      // act
      const request = GetSpeakingSessionRequest(userId: tUserId);

      // assert
      expect(request.userId, tUserId);
    });

    test('should support copyWith', () {
      // arrange
      const tOriginalUserId = 123;
      const tNewUserId = 456;
      const originalRequest = GetSpeakingSessionRequest(
        userId: tOriginalUserId,
      );

      // act
      final newRequest = originalRequest.copyWith(userId: tNewUserId);

      // assert
      expect(originalRequest.userId, tOriginalUserId);
      expect(newRequest.userId, tNewUserId);
    });

    test('should support equality comparison', () {
      // arrange
      const tUserId = 123;
      const request1 = GetSpeakingSessionRequest(userId: tUserId);
      const request2 = GetSpeakingSessionRequest(userId: tUserId);
      const request3 = GetSpeakingSessionRequest(userId: 456);

      // assert
      expect(request1, equals(request2));
      expect(request1, isNot(equals(request3)));
    });
  });
}
