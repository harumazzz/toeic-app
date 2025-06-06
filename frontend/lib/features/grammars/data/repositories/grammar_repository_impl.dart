import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/grammar.dart';
import '../../domain/repositories/grammar_repository.dart';
import '../data_sources/grammar_remote_data_source.dart';
import '../models/grammar_model.dart';

part 'grammar_repository_impl.g.dart';

@riverpod
GrammarRepository grammarRepository(final Ref ref) {
  final grammarRemoteDataSource = ref.watch(grammarRemoteDataSourceProvider);
  return GrammarRepositoryImpl(
    grammarRemoteDataSource: grammarRemoteDataSource,
  );
}

class GrammarRepositoryImpl implements GrammarRepository {
  const GrammarRepositoryImpl({
    required this.grammarRemoteDataSource,
  });

  final GrammarRemoteDataSource grammarRemoteDataSource;

  @override
  Future<Either<Failure, List<Grammar>>> getAllGrammars({
    required final int limit,
    required final int offset,
  }) async {
    try {
      final grammars = await grammarRemoteDataSource.getAllGrammars(
        limit: limit,
        offset: offset,
      );
      return Right([...grammars.map((final e) => e.toEntity())]);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.toString()));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Grammar>>> getAllGrammarsByLevel({
    required final int level,
    required final int limit,
    required final int offset,
  }) async {
    try {
      final grammars = await grammarRemoteDataSource.getAllGrammarsByLevel(
        level: level,
        limit: limit,
        offset: offset,
      );
      return Right([...grammars.map((final e) => e.toEntity())]);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.toString()));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Grammar>>> getAllGrammarsByTag({
    required final int tag,
    required final int limit,
    required final int offset,
  }) async {
    try {
      final grammars = await grammarRemoteDataSource.getAllGrammarsByTag(
        tag: tag.toString(),
        limit: limit,
        offset: offset,
      );
      return Right([...grammars.map((final e) => e.toEntity())]);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.toString()));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Grammar>> getGrammarById({
    required final int id,
  }) async {
    try {
      final grammar = await grammarRemoteDataSource.getGrammarById(
        id: id,
      );
      return Right(grammar.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.toString()));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Grammar>> getRandomGrammar() async {
    try {
      final grammar = await grammarRemoteDataSource.getRandomGrammar();
      return Right(grammar.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.toString()));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Grammar>>> searchGrammars({
    required final String query,
    required final int limit,
    required final int offset,
  }) async {
    try {
      final grammars = await grammarRemoteDataSource.searchGrammars(
        query: query,
        limit: limit,
        offset: offset,
      );
      return Right([...grammars.map((final e) => e.toEntity())]);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.toString()));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Grammar>>> getRelatedGrammars({
    required final List<int> ids,
  }) async {
    try {
      final grammars = await grammarRemoteDataSource.getRelatedGrammars(
        ids: GetRelatedGrammarsRequest(ids: ids),
      );
      return Right([...grammars.map((final e) => e.toEntity())]);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.toString()));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
