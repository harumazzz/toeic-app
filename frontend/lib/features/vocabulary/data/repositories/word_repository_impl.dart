import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/word_repository.dart';
import '../data_sources/word_remote_datasources.dart';
import '../models/word_model.dart';

part 'word_repository_impl.g.dart';

@riverpod
WordRepository wordRepository(final Ref ref) {
  final remoteDataSource = ref.watch(wordRemoteDataSourceProvider);
  return WordRepositoryImpl(remoteDataSource: remoteDataSource);
}

class WordRepositoryImpl implements WordRepository {
  const WordRepositoryImpl({
    required final WordRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final WordRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<Word>>> getAllWords({
    required final int offset,
    required final int limit,
  }) async {
    try {
      final words = await _remoteDataSource.getWords(
        offset: offset,
        limit: limit,
      );
      return Right([...words.map((final e) => e.toEntity())]);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Left(
          Failure.serverFailure(message: e.message ?? 'Words not found'),
        );
      } else if (e.response?.statusCode == 500) {
        return Left(
          Failure.serverFailure(
            message: e.message ?? 'Server error, please try again later',
          ),
        );
      } else {
        return Left(
          Failure.networkFailure(
            message: e.message ?? 'An unexpected error occurred',
          ),
        );
      }
    }
  }

  @override
  Future<Either<Failure, Word>> getWordById({
    required final int id,
  }) async {
    try {
      final wordModel = await _remoteDataSource.getWord(id);
      return Right(wordModel.toEntity());
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Left(
          Failure.serverFailure(message: e.message ?? 'Word not found'),
        );
      } else if (e.response?.statusCode == 500) {
        return Left(
          Failure.serverFailure(
            message: e.message ?? 'Server error, please try again later',
          ),
        );
      } else {
        return Left(
          Failure.networkFailure(
            message: e.message ?? 'An unexpected error occurred',
          ),
        );
      }
    }
  }
}
