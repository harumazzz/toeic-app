import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/exam_attempt_repository_impl.dart';
import '../entities/exam.dart';
import '../repositories/exam_attempt_repository.dart';

part 'create_exam_attempt.freezed.dart';
part 'create_exam_attempt.g.dart';

@riverpod
CreateExamAttempt createExamAttempt(
  final Ref ref,
) {
  final repository = ref.watch(examAttemptRepositoryProvider);
  return CreateExamAttempt(repository);
}

class CreateExamAttempt
    implements UseCase<ExamAttempt, CreateExamAttemptParams> {
  const CreateExamAttempt(this._repository);

  final ExamAttemptRepository _repository;

  @override
  Future<Either<Failure, ExamAttempt>> call(
    final CreateExamAttemptParams params,
  ) async => _repository.createExamAttempt(params.examAttempt);
}

@freezed
abstract class CreateExamAttemptParams with _$CreateExamAttemptParams {
  const factory CreateExamAttemptParams({
    required final ExamRequest examAttempt,
  }) = _CreateExamAttemptParams;
}
