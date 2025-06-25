import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/exam.dart';
import '../../domain/repositories/exam_repository.dart';
import '../datasources/exam_remote_data_source.dart';
import '../models/exam_model.dart';

part 'exam_repository_impl.g.dart';

@riverpod
ExamRepository examRepository(
  final Ref ref,
) {
  final examRemoteDataSource = ref.watch(examRemoteDataSourceProvider);
  return ExamRepositoryImpl(
    remoteDataSource: examRemoteDataSource,
  );
}

class ExamRepositoryImpl implements ExamRepository {
  const ExamRepositoryImpl({
    required this.remoteDataSource,
  });

  final ExamRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, Exam>> getExamQuestions(
    final int examId,
  ) async {
    try {
      final remoteExam = await remoteDataSource.getExamQuestions(
        examId: examId,
      );
      return Right(remoteExam.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
