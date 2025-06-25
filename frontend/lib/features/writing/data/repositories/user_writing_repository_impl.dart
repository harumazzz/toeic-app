import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user_writing.dart';
import '../../domain/repositories/user_writing_repository.dart';
import '../data_sources/user_writing_remote_data_source.dart';
import '../models/user_writing_model.dart';

part 'user_writing_repository_impl.g.dart';

@riverpod
UserWritingRepository userWritingRepository(
  final Ref ref,
) {
  final remoteDataSource = ref.watch(userWritingRemoteDataSourceProvider);
  return UserWritingRepositoryImpl(remoteDataSource);
}

class UserWritingRepositoryImpl implements UserWritingRepository {
  const UserWritingRepositoryImpl(this._remoteDataSource);

  final UserWritingRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, UserWriting>> createUserWriting({
    required final UserWritingRequest request,
  }) async {
    try {
      final requestModel = request.toModel();
      final response = await _remoteDataSource.createUserWriting(
        request: requestModel,
      );
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserWriting>> getUserWriting({
    required final int id,
  }) async {
    try {
      final response = await _remoteDataSource.getUserWriting(id: id);
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserWriting>>> listUserWritingsByUserId({
    required final int userId,
  }) async {
    try {
      final response = await _remoteDataSource.listUserWritingsByUserId(
        userId: userId,
      );
      return Right([...response.map((final e) => e.toEntity())]);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserWriting>>> listUserWritingsByPromptId({
    required final int promptId,
  }) async {
    try {
      final response = await _remoteDataSource.listUserWritingsByPromptId(
        promptId: promptId,
      );
      return Right([...response.map((final e) => e.toEntity())]);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserWriting>> updateUserWriting({
    required final int id,
    required final UserWritingUpdateRequest request,
  }) async {
    try {
      final requestModel = request.toModel();
      final response = await _remoteDataSource.updateUserWriting(
        id: id,
        request: requestModel,
      );
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Success>> deleteUserWriting({
    required final int id,
  }) async {
    try {
      await _remoteDataSource.deleteUserWriting(id: id);
      return const Right(Success());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
