import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/exam/data/datasources/exam_attempt_remote_data_source.dart';
import 'package:learn/features/exam/data/models/exam_model.dart';
import 'package:learn/features/exam/data/repositories/exam_attempt_repository_impl.dart';
import 'package:learn/features/exam/domain/entities/exam.dart';
import 'package:mocktail/mocktail.dart';

class MockExamAttemptRemoteDataSource extends Mock
    implements ExamAttemptRemoteDataSource {}

class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeExamRequest extends Fake implements ExamRequest {}

class FakeExamModelRequest extends Fake implements ExamModelRequest {}

void main() {
  late ExamAttemptRepositoryImpl repository;
  late MockExamAttemptRemoteDataSource mockRemoteDataSource;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeExamRequest());
    registerFallbackValue(FakeExamModelRequest());
  });

  setUp(() {
    mockRemoteDataSource = MockExamAttemptRemoteDataSource();
    repository = ExamAttemptRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
    );
  });

  group('ExamAttemptRepositoryImpl', () {
    final tExamAttemptModels = [
      ExamAttemptModel(
        attemptId: 1,
        examId: 1,
        userId: 1,
        startTime: DateTime.now().toIso8601String(),
        endTime: DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        score: '85',
        status: 'completed',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
    ];
    final tExamAttempts = tExamAttemptModels
        .map((final model) => model.toEntity())
        .toList();

    const tExamRequest = ExamRequest(
      examId: 1,
    );

    final tExamAttemptModel = ExamAttemptModel(
      attemptId: 1,
      examId: 1,
      userId: 1,
      startTime: DateTime.now().toIso8601String(),
      endTime: '',
      score: '',
      status: 'in_progress',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    final tExamAttempt = tExamAttemptModel.toEntity();

    group('createExamAttempt', () {
      test(
        'should return ExamAttempts',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.createExamAttempt(
              examAttempt: any(named: 'examAttempt'),
            ),
          ).thenAnswer((_) async => tExamAttemptModel);

          // act
          final result = await repository.createExamAttempt(tExamRequest);

          // assert
          verify(
            () => mockRemoteDataSource.createExamAttempt(
              examAttempt: any(named: 'examAttempt'),
            ),
          );
          expect(result, Right<Failure, ExamAttempt>(tExamAttempt));
        },
      );

      test(
        'should return ServerFailure',
        () async {
          // arrange
          final dioException = DioException(
            requestOptions: RequestOptions(),
            message: 'Failed to create exam attempt',
          );
          when(
            () => mockRemoteDataSource.createExamAttempt(
              examAttempt: any(named: 'examAttempt'),
            ),
          ).thenThrow(dioException);

          // act
          final result = await repository.createExamAttempt(tExamRequest);

          // assert
          verify(
            () => mockRemoteDataSource.createExamAttempt(
              examAttempt: any(named: 'examAttempt'),
            ),
          );
          expect(
            result,
            const Left<Failure, ExamAttempt>(
              ServerFailure(message: 'Failed to create exam attempt'),
            ),
          );
        },
      );
    });

    group('getExamAttemptById', () {
      const tAttemptId = 1;

      test(
        'should return ExamAttemptW',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.getExamAttemptById(id: tAttemptId),
          ).thenAnswer((_) async => tExamAttemptModel);

          // act
          final result = await repository.getExamAttemptById(tAttemptId);

          // assert
          verify(
            () => mockRemoteDataSource.getExamAttemptById(id: tAttemptId),
          );
          expect(result, Right<Failure, ExamAttempt>(tExamAttempt));
        },
      );

      test(
        'should return ServerFailure',
        () async {
          // arrange
          final dioException = DioException(
            requestOptions: RequestOptions(),
            message: 'Exam attempt not found',
          );
          when(
            () => mockRemoteDataSource.getExamAttemptById(id: tAttemptId),
          ).thenThrow(dioException);

          // act
          final result = await repository.getExamAttemptById(tAttemptId);

          // assert
          verify(
            () => mockRemoteDataSource.getExamAttemptById(id: tAttemptId),
          );
          expect(
            result,
            const Left<Failure, ExamAttempt>(
              ServerFailure(message: 'Exam attempt not found'),
            ),
          );
        },
      );
    });

    group('completeExamAttempt', () {
      const tAttemptId = 1;

      test(
        'should return updated ExamAttempt',
        () async {
          // arrange
          final completedAttempt = tExamAttemptModel.copyWith(
            endTime: DateTime.now().toIso8601String(),
            score: '85',
            status: 'completed',
          );
          when(
            () => mockRemoteDataSource.completeExamAttempt(id: tAttemptId),
          ).thenAnswer((_) async => completedAttempt);

          // act
          final result = await repository.completeExamAttempt(tAttemptId);

          // assert
          verify(
            () => mockRemoteDataSource.completeExamAttempt(id: tAttemptId),
          );
          expect(
            result,
            Right<Failure, ExamAttempt>(completedAttempt.toEntity()),
          );
        },
      );

      test(
        'should return ServerFailure',
        () async {
          // arrange
          final dioException = DioException(
            requestOptions: RequestOptions(),
            message: 'Failed to complete exam',
          );
          when(
            () => mockRemoteDataSource.completeExamAttempt(id: tAttemptId),
          ).thenThrow(dioException);

          // act
          final result = await repository.completeExamAttempt(tAttemptId);

          // assert
          verify(
            () => mockRemoteDataSource.completeExamAttempt(id: tAttemptId),
          );
          expect(
            result,
            const Left<Failure, ExamAttempt>(
              ServerFailure(message: 'Failed to complete exam'),
            ),
          );
        },
      );
    });
  });
}
