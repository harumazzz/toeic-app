import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/result.dart';
import '../../domain/repositories/answer_submit_repository.dart';
import '../datasources/user_answer_remote_data_source.dart';
import '../models/result_model.dart';

part 'answer_submit_repository_impl.g.dart';

@riverpod
AnswerSubmitRepository answerSubmitRepository(
  final Ref ref,
) {
  final userAnswerRemoteDataSource = ref.watch(
    userAnswerRemoteDataSourceProvider,
  );
  return AnswerSubmitRepositoryImpl(
    remoteDataSource: userAnswerRemoteDataSource,
  );
}

class AnswerSubmitRepositoryImpl implements AnswerSubmitRepository {
  const AnswerSubmitRepositoryImpl({
    required this.remoteDataSource,
  });
  final UserAnswerRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, UserResult>> submitAnswers({
    required final Answer request,
  }) async {
    try {
      final response = await remoteDataSource.submitAnswers(
        request: request.toModel(),
      );
      return Right(response.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
