import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/speaking.dart';
import '../../domain/repositories/speaking_repository.dart';
import '../data_sources/speaking_remote_data_source.dart';
import '../models/speaking_model.dart';

part 'speaking_repository_impl.g.dart';

@riverpod
SpeakingRepository speakingRepository(
  final Ref ref,
) {
  final dataSource = ref.watch(speakingRemoteDataSourceProvider);
  return SpeakingRepositoryImpl(
    speakingRemoteDataSource: dataSource,
  );
}

class SpeakingRepositoryImpl implements SpeakingRepository {
  const SpeakingRepositoryImpl({
    required final SpeakingRemoteDataSource speakingRemoteDataSource,
  }) : _speakingRemoteDataSource = speakingRemoteDataSource;

  final SpeakingRemoteDataSource _speakingRemoteDataSource;

  @override
  Future<Either<Failure, SpeakingTurn>> createNewTurn({
    required final SpeakingTurnRequest request,
  }) async {
    try {
      final response = await _speakingRemoteDataSource.createNewTurn(
        request: request.toModel(),
      );
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.error.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Speaking>> createSession({
    required final SpeakingRequest speakingRequest,
  }) async {
    try {
      final response = await _speakingRemoteDataSource.createSession(
        speakingRequest: speakingRequest.toModel(),
      );
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.error.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Success>> deleteSession({
    required final int id,
  }) async {
    try {
      await _speakingRemoteDataSource.deleteSession(id: id);
      return const Right(Success());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.error.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Success>> deleteTurn({
    required final int id,
  }) async {
    try {
      await _speakingRemoteDataSource.deleteTurn(id: id);
      return const Right(Success());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.error.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Speaking>> getSessionById({
    required final int id,
  }) async {
    try {
      final response = await _speakingRemoteDataSource.getSessionById(id: id);
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.error.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Speaking>>> getSpeakingSessions({
    required final int userId,
  }) async {
    try {
      final response = await _speakingRemoteDataSource.getSpeakingSessions(
        userId: userId,
      );
      return Right([...response.map((final e) => e.toEntity())]);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.error.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SpeakingTurn>> getTurnById({
    required final int id,
  }) async {
    try {
      final response = await _speakingRemoteDataSource.getTurnById(id: id);
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.error.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Speaking>> updateSession({
    required final int id,
    required final SpeakingRequest speakingRequest,
  }) async {
    try {
      final response = await _speakingRemoteDataSource.updateSession(
        id: id,
        speakingRequest: speakingRequest.toModel(),
      );
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.error.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SpeakingTurn>> updateTurn({
    required final int id,
    required final SpeakingTurnRequest request,
  }) async {
    try {
      final response = await _speakingRemoteDataSource.updateTurn(
        id: id,
        request: request.toModel(),
      );
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.error.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SpeakingTurn>>> getSpeakingTurns({
    required final int sessionId,
  }) async {
    try {
      final response = await _speakingRemoteDataSource.getSpeakingTurns(
        sessionId: sessionId,
      );
      return Right([...response.map((final e) => e.toEntity())]);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.error.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
