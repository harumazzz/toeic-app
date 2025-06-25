import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/exam_attempt_repository_impl.dart';
import '../entities/exam.dart';
import '../repositories/exam_attempt_repository.dart';

part 'get_exam_attempt_by_id.freezed.dart';
part 'get_exam_attempt_by_id.g.dart';

@riverpod
GetExamAttemptById getExamAttemptById(
  final Ref ref,
) {
  final repository = ref.watch(examAttemptRepositoryProvider);
  return GetExamAttemptById(repository);
}

class GetExamAttemptById
    implements UseCase<ExamAttempt, GetExamAttemptByIdParams> {
  const GetExamAttemptById(this._repository);

  final ExamAttemptRepository _repository;

  @override
  Future<Either<Failure, ExamAttempt>> call(
    final GetExamAttemptByIdParams params,
  ) async => _repository.getExamAttemptById(params.id);
}

@freezed
sealed class GetExamAttemptByIdParams with _$GetExamAttemptByIdParams {
  const factory GetExamAttemptByIdParams({
    required final int id,
  }) = _GetExamAttemptByIdParams;
}
