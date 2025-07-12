import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/core/error/failures.dart';
import 'package:learn/features/exam/data/datasources/exam_remote_data_source.dart';
import 'package:learn/features/exam/data/models/exam_model.dart';
import 'package:learn/features/exam/data/repositories/exam_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockExamRemoteDataSource extends Mock implements ExamRemoteDataSource {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  late ExamRepositoryImpl repository;
  late MockExamRemoteDataSource mockRemoteDataSource;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    mockRemoteDataSource = MockExamRemoteDataSource();
    repository = ExamRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
    );
  });

  group('ExamRepositoryImpl', () {
    const tExamId = 1;
    const tExamModel = ExamModel(
      examId: tExamId,
      examTitle: 'Test Exam',
      totalQuestions: 100,
      parts: [],
    );
    final tExam = tExamModel.toEntity();

    group('getExamQuestions', () {
      test(
        'should return Exam when the call to remote data source is successful',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.getExamQuestions(examId: tExamId),
          ).thenAnswer((_) async => tExamModel);

          // act
          final result = await repository.getExamQuestions(tExamId);

          // assert
          verify(
            () => mockRemoteDataSource.getExamQuestions(examId: tExamId),
          );
          expect(result, Right(tExam));
        },
      );

      test(
        'should return ServerFailure when the call to remote data source throws DioException',
        () async {
          // arrange
          final dioException = DioException(
            requestOptions: RequestOptions(),
            message: 'Network error',
          );
          when(
            () => mockRemoteDataSource.getExamQuestions(examId: tExamId),
          ).thenThrow(dioException);

          // act
          final result = await repository.getExamQuestions(tExamId);

          // assert
          verify(
            () => mockRemoteDataSource.getExamQuestions(examId: tExamId),
          );
          expect(result, const Left(ServerFailure(message: 'Network error')));
        },
      );

      test(
        'should return ServerFailure when the call to remote data source throws general exception',
        () async {
          // arrange
          when(
            () => mockRemoteDataSource.getExamQuestions(examId: tExamId),
          ).thenThrow(Exception('Unexpected error'));

          // act
          final result = await repository.getExamQuestions(tExamId);

          // assert
          verify(
            () => mockRemoteDataSource.getExamQuestions(examId: tExamId),
          );
          expect(
            result,
            const Left(ServerFailure(message: 'Exception: Unexpected error')),
          );
        },
      );
    });
  });
}
