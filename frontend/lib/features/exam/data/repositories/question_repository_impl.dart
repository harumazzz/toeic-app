import 'package:dart_either/dart_either.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/question_repository.dart';
import '../data_sources/question_remote_data_source.dart';
import '../model/question_model.dart';

part 'question_repository_impl.g.dart';

@riverpod
QuestionRepository questionRepository(final Ref ref) {
  final dataSource = ref.watch(questionRemoteDataSourceProvider);
  return QuestionRepositoryImpl(dataSource);
}

class QuestionRepositoryImpl implements QuestionRepository {

  const QuestionRepositoryImpl(this._remoteDataSource);

  final QuestionRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, Question>> getQuestionById({
    required final int questionId,
  }) async {
    try {
      final response = await _remoteDataSource.getQuestionById(
        questionId: questionId,
      );
      return Right(response.toEntity());
    }
    on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    }
    catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Question>>> getQuestionsByContentId({
    required final int contentId,
  }) async {
    try {
      final response = await _remoteDataSource.getQuestionsByContentId(
        contentId: contentId,
      );
      return Right([...response.map((final e) => e.toEntity())]);
    }
    on DioException catch (e) {
      return Left(ServerFailure(message: e.message.toString()));
    }
    catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
