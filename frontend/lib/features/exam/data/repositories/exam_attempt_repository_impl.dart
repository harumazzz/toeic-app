import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/exam.dart';
import '../../domain/repositories/exam_attempt_repository.dart';
import '../datasources/exam_attempt_remote_data_source.dart';
import '../models/exam_model.dart';

part 'exam_attempt_repository_impl.g.dart';

@riverpod
ExamAttemptRepository examAttemptRepository(
  final Ref ref,
) {
  final examAttemptRemoteDataSource = ref.watch(
    examAttemptRemoteDataSourceProvider,
  );
  return ExamAttemptRepositoryImpl(
    remoteDataSource: examAttemptRemoteDataSource,
  );
}

class ExamAttemptRepositoryImpl implements ExamAttemptRepository {
  const ExamAttemptRepositoryImpl({
    required this.remoteDataSource,
  });

  final ExamAttemptRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<ExamAttempt>>> getExamAttempts() async {
    try {
      final response = await remoteDataSource.getExamAttempts();
      return Right(
        [...response.map((final attempt) => attempt.toEntity())],
      );
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExamAttempt>> createExamAttempt(
    final ExamRequest examAttempt,
  ) async {
    try {
      final response = await remoteDataSource.createExamAttempt(
        examAttempt: examAttempt.toModel(),
      );
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExamStats>> getExamAttemptStats() async {
    try {
      final response = await remoteDataSource.getExamAttemptStats();
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExamAttempt>> getExamAttemptById(
    final int id,
  ) async {
    try {
      final response = await remoteDataSource.getExamAttemptById(id: id);
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExamAttempt>> updateExamAttempt(
    final int id,
    final UpdateExamAttempt examAttempt,
  ) async {
    try {
      final response = await remoteDataSource.updateExamAttempt(
        id: id,
        examAttempt: examAttempt.toModel(),
      );
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExamAttempt(
    final int id,
  ) async {
    try {
      await remoteDataSource.deleteExamAttempt(id: id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExamAttempt>> abandonExamAttempt(
    final int id,
  ) async {
    try {
      final response = await remoteDataSource.abandonExamAttempt(id: id);
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExamAttempt>> completeExamAttempt(
    final int id,
  ) async {
    try {
      final response = await remoteDataSource.completeExamAttempt(id: id);
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
