import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/speaking/data/data_sources/speaking_remote_data_source.dart';
import 'package:learn/features/speaking/data/models/speaking_model.dart';
import 'package:learn/features/speaking/data/repositories/speaking_repository_impl.dart';
import 'package:learn/features/speaking/domain/entities/speaking.dart';
import 'package:mocktail/mocktail.dart';

class MockSpeakingRemoteDataSource extends Mock
    implements SpeakingRemoteDataSource {}

void main() {
  late SpeakingRepositoryImpl repository;
  late MockSpeakingRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockSpeakingRemoteDataSource();
    repository = SpeakingRepositoryImpl(
      speakingRemoteDataSource: mockRemoteDataSource,
    );
  });

  group('SpeakingRepositoryImpl - getSpeakingSessions', () {
    const tUserId = 1;
    final tSpeakingModels = [
      SpeakingModel(
        id: 1,
        userId: tUserId,
        sessionTopic: 'TOEIC Speaking Practice',
        startTime: DateTime(2023, 1, 1, 10),
        endTime: DateTime(2023, 1, 1, 11),
        updatedAt: DateTime(2023, 1, 1, 11),
      ),
      SpeakingModel(
        id: 2,
        userId: tUserId,
        sessionTopic: 'Business English Speaking',
        startTime: DateTime(2023, 1, 2, 14),
        endTime: DateTime(2023, 1, 2, 15),
        updatedAt: DateTime(2023, 1, 2, 15),
      ),
    ];

    tSpeakingModels
        .map(
          (final model) => model.toEntity(),
        )
        .toList();

    test('should return ServerFailure when DioException occurs', () async {
      // arrange
      final tDioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        error: 'Server error',
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
      );

      when(
        () => mockRemoteDataSource.getSpeakingSessions(
          userId: any(named: 'userId'),
        ),
      ).thenThrow(tDioException);

      // act
      final result = await repository.getSpeakingSessions(userId: tUserId);

      // assert
      expect(result, isA<Left<Failure, List<Speaking>>>());
      expect(
        (result as Left).value,
        isA<ServerFailure>(),
      );
      verify(() => mockRemoteDataSource.getSpeakingSessions(userId: tUserId));
      verifyNoMoreInteractions(mockRemoteDataSource);
    });

    test('should return ServerFailure when general exception occurs', () async {
      // arrange
      when(
        () => mockRemoteDataSource.getSpeakingSessions(
          userId: any(named: 'userId'),
        ),
      ).thenThrow(Exception('Unexpected error'));

      // act
      final result = await repository.getSpeakingSessions(userId: tUserId);

      // assert
      expect(result, isA<Left<Failure, List<Speaking>>>());
      expect(
        (result as Left).value,
        isA<ServerFailure>(),
      );
      verify(() => mockRemoteDataSource.getSpeakingSessions(userId: tUserId));
      verifyNoMoreInteractions(mockRemoteDataSource);
    });

    test('should handle different user IDs correctly', () async {
      // arrange
      const tDifferentUserId = 999;
      final tDifferentUserModels = [
        SpeakingModel(
          id: 3,
          userId: tDifferentUserId,
          sessionTopic: 'Advanced TOEIC Speaking',
          startTime: DateTime(2023, 1, 3, 9),
          endTime: DateTime(2023, 1, 3, 10, 30),
          updatedAt: DateTime(2023, 1, 3, 10, 30),
        ),
      ];

      when(
        () => mockRemoteDataSource.getSpeakingSessions(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => tDifferentUserModels);

      // assert
      tDifferentUserModels.map((final model) => model.toEntity()).toList();
      verifyNever(
        () =>
            mockRemoteDataSource.getSpeakingSessions(userId: tDifferentUserId),
      );
      verifyNoMoreInteractions(mockRemoteDataSource);
    });

    test('should handle large number of sessions', () async {
      // arrange
      final tLargeSessionList = List.generate(
        100,
        (final index) => SpeakingModel(
          id: index + 1,
          userId: tUserId,
          sessionTopic: 'Session ${index + 1}',
          startTime: DateTime(2023).add(Duration(hours: index)),
          endTime: DateTime(2023).add(Duration(hours: index + 1)),
          updatedAt: DateTime(2023).add(Duration(hours: index + 1)),
        ),
      );

      when(
        () => mockRemoteDataSource.getSpeakingSessions(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => tLargeSessionList);

      // act
      final result = await repository.getSpeakingSessions(userId: tUserId);

      // assert
      expect(result, isA<Right<Failure, List<Speaking>>>());
      final sessions = (result as Right).value as List<Speaking>;
      expect(sessions.length, 100);
      expect(sessions.first.id, 1);
      expect(sessions.last.id, 100);
      verify(() => mockRemoteDataSource.getSpeakingSessions(userId: tUserId));
      verifyNoMoreInteractions(mockRemoteDataSource);
    });
  });
}
