import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user_writing.dart';
import '../../domain/entities/writing_prompt.dart';
import '../../domain/repositories/writing_repository.dart';
import '../data_sources/writing_remote_data_source.dart';
import '../models/user_writing_model.dart';
import '../models/writing_prompt_model.dart';

part 'writing_repository_impl.g.dart';

@riverpod
WritingRepository writingRepository(
  final Ref ref,
) {
  final remoteDataSource = ref.watch(writingRemoteDataSourceProvider);
  return WritingRepositoryImpl(remoteDataSource);
}

class WritingRepositoryImpl implements WritingRepository {
  WritingRepositoryImpl(this._remoteDataSource);

  final WritingRemoteDataSource _remoteDataSource;

  // Writing Prompts
  @override
  Future<Either<Failure, WritingPrompt>> createWritingPrompt({
    required final WritingPromptRequest request,
  }) async {
    try {
      final requestModel = request.toModel();
      final response = await _remoteDataSource.createWritingPrompt(
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
  Future<Either<Failure, WritingPrompt>> getWritingPrompt({
    required final int id,
  }) async {
    try {
      final response = await _remoteDataSource.getWritingPrompt(id: id);
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WritingPrompt>>> listWritingPrompts() async {
    try {
      final response = await _remoteDataSource.listWritingPrompts();
      return Right([...response.map((final e) => e.toEntity())]);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WritingPrompt>> updateWritingPrompt({
    required final int id,
    required final WritingPromptRequest request,
  }) async {
    try {
      final requestModel = request.toModel();
      final response = await _remoteDataSource.updateWritingPrompt(
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
  Future<Either<Failure, Success>> deleteWritingPrompt({
    required final int id,
  }) async {
    try {
      await _remoteDataSource.deleteWritingPrompt(id: id);
      return const Right(Success());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // User Writings
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
