

import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/question_repository_impl.dart';
import '../entities/question.dart';
import '../repositories/question_repository.dart';

part 'get_question.g.dart';
part 'get_question.freezed.dart';

@riverpod
GetQuestion getQuestion(final Ref ref) {
  final questionRepository = ref.watch(questionRepositoryProvider);
  return GetQuestion(questionRepository: questionRepository);
}

@riverpod
GetQuestionsByContent getQuestionsByContent(final Ref ref) {
  final questionRepository = ref.watch(questionRepositoryProvider);
  return GetQuestionsByContent(questionRepository: questionRepository);
}

@freezed
sealed class GetQuestionParams with _$GetQuestionParams {
  const factory GetQuestionParams({
    required final int questionId,
  }) = _GetQuestionParams;
}

@freezed
sealed class GetQuestionsByContentParams with _$GetQuestionsByContentParams {
  const factory GetQuestionsByContentParams({
    required final int contentId,
  }) = _GetQuestionsByContentParams;
}

class GetQuestion implements UseCase<Question, GetQuestionParams> {

  const GetQuestion({required this.questionRepository});

  final QuestionRepository questionRepository;

  @override
  Future<Either<Failure, Question>> call(
    final GetQuestionParams params,
  ) async => questionRepository.getQuestionById(
      questionId: params.questionId,
    );
}

class GetQuestionsByContent implements 
UseCase<List<Question>, GetQuestionsByContentParams> {

  const GetQuestionsByContent({required this.questionRepository});

  final QuestionRepository questionRepository;

  @override
  Future<Either<Failure, List<Question>>> call(
    final GetQuestionsByContentParams params,
  ) async => questionRepository.getQuestionsByContentId(
      contentId: params.contentId,
    );
}
