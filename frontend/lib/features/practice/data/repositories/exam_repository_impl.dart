import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/exam.dart';
import '../../domain/repositories/exam_repository.dart';
import '../data_sources/exam_remote_data_source.dart';
import '../model/exam_model.dart';

part 'exam_repository_impl.g.dart';

@riverpod
ExamRepositoryImpl examRepository(final Ref ref) {
  final remoteDataSource = ref.watch(examRemoteDataSourceProvider);
  return ExamRepositoryImpl(remoteDataSource);
}

class ExamRepositoryImpl implements ExamRepository {
  const ExamRepositoryImpl(this.remoteDataSource);

  final ExamRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, Exam>> getExamById({
    required final int examId,
  }) async {
    try {
      final exam = await remoteDataSource.getExamById(
        examId: examId,
      );
      return Right(exam.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Exam>>> getExams({
    required final int limit,
    required final int offset,
  }) async {
    try {
      final exams = await remoteDataSource.getExams(
        limit: limit,
        offset: offset,
      );
      return Right([...exams.map((final e) => e.toEntity())]);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
