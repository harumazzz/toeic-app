import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/exam.dart';
import '../../domain/entities/result.dart';
import '../../domain/repositories/user_answer_repository.dart';
import '../datasources/user_answer_remote_data_source.dart';
import '../models/exam_model.dart';
import '../models/result_model.dart';

part 'user_answer_repository_impl.g.dart';

@riverpod
UserAnswerRepository userAnswerRepository(
  final Ref ref,
) {
  final userAnswerRemoteDataSource = ref.watch(
    userAnswerRemoteDataSourceProvider,
  );
  return UserAnswerRepositoryImpl(
    remoteDataSource: userAnswerRemoteDataSource,
  );
}

class UserAnswerRepositoryImpl implements UserAnswerRepository {
  const UserAnswerRepositoryImpl({
    required this.remoteDataSource,
  });

  final UserAnswerRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, UserAnswerResponse>> getUserAnswers() async {
    try {
      final response = await remoteDataSource.getUserAnswers();
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserAnswer>> createUserAnswer(
    final UserAnswerRequest userAnswer,
  ) async {
    try {
      final response = await remoteDataSource.createUserAnswer(
        userAnswer: userAnswer.toModel(),
      );
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserAnswer>> getUserAnswerById(
    final int id,
  ) async {
    try {
      final response = await remoteDataSource.getUserAnswerById(id: id);
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserAnswer>> updateUserAnswer(
    final int id,
    final UpdateUserAnswerRequest userAnswer,
  ) async {
    try {
      final response = await remoteDataSource.updateUserAnswer(
        id: id,
        userAnswer: userAnswer.toModel(),
      );
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUserAnswer(
    final int id,
  ) async {
    try {
      await remoteDataSource.deleteUserAnswer(id: id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserAnswer>> abandonUserAnswer(
    final int id,
  ) async {
    try {
      final response = await remoteDataSource.abandonUserAnswer(id: id);
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserAnswer>> completeUserAnswer(
    final int id,
  ) async {
    try {
      final response = await remoteDataSource.completeUserAnswer(id: id);
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
