import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/exam_repository_impl.dart';
import '../entities/exam.dart';
import '../repositories/exam_repository.dart';

part 'get_exam_questions.freezed.dart';
part 'get_exam_questions.g.dart';

@riverpod
GetExamQuestions getExamQuestions(
  final Ref ref,
) {
  final repository = ref.watch(examRepositoryProvider);
  return GetExamQuestions(repository);
}

class GetExamQuestions implements UseCase<Exam, GetExamQuestionsParams> {
  const GetExamQuestions(this._repository);

  final ExamRepository _repository;

  @override
  Future<Either<Failure, Exam>> call(
    final GetExamQuestionsParams params,
  ) async => _repository.getExamQuestions(
    params.examId,
  );
}

@freezed
abstract class GetExamQuestionsParams with _$GetExamQuestionsParams {
  const factory GetExamQuestionsParams({
    required final int examId,
  }) = _GetExamQuestionsParams;
}
