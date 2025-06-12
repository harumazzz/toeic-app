import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/progress.dart';
import '../../domain/repositories/progress_repository.dart';
import '../data_sources/progress_remote_data_source.dart';
import '../model/progress_model.dart';

part 'progress_repository_impl.g.dart';

@riverpod
ProgressRepository progressRepository(final Ref ref) {
  final dataSource = ref.watch(progressRemoteDataSourceProvider);
  return ProgressRepositoryImpl(dataSource);
}

class ProgressRepositoryImpl implements ProgressRepository {
  const ProgressRepositoryImpl(this._remoteDataSource);

  final ProgressRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, WordProgress>> addNewProgress({
    required final WordProgressRequest request,
  }) async {
    try {
      final response = await _remoteDataSource.addNewProgress(
        request: request.toModel(),
      );
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Success>> deleteProgress({
    required final int wordId,
  }) async {
    try {
      final _ = await _remoteDataSource.deleteWordProgress(
        wordId: wordId,
      );
      return const Right(Success());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Progress?>> getProgressById({
    required final int wordId,
  }) async {
    try {
      final response = await _remoteDataSource.getProgressById(
        progressId: wordId,
      );
      if (response == null) {
        return const Right(null);
      }
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e, s) {
      debugPrintStack(stackTrace: s);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WordProgress>>> getReviewsProgress({
    required final int limit,
  }) async {
    try {
      final response = await _remoteDataSource.getReviewWords(
        limit: limit,
      );
      return Right([...response.map((final e) => e.toEntity())]);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WordProgress>> getWordProgressById({
    required final int wordId,
  }) async {
    try {
      final response = await _remoteDataSource.getWordProgressById(
        wordId: wordId,
      );
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WordProgress>> updateProgress({
    required final int wordId,
    required final WordProgressRequest request,
  }) async {
    try {
      final response = await _remoteDataSource.updateWordProgress(
        wordId: wordId,
        request: request.toModel(),
      );
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WordProgress>>> getWordProgress({
    required final int limit,
    required final int offset,
  }) async {
    try {
      final response = await _remoteDataSource.getWordProgress(
        limit: limit,
        offset: offset,
      );
      return Right([
        ...response.map((final e) => e.toEntity()),
      ]);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e, s) {
      debugPrintStack(stackTrace: s);
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
