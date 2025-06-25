import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/exam_attempt_repository_impl.dart';
import '../entities/exam.dart';
import '../repositories/exam_attempt_repository.dart';

part 'get_exam_attempts.g.dart';

@riverpod
GetExamAttempts getExamAttempts(
  final Ref ref,
) {
  final repository = ref.watch(examAttemptRepositoryProvider);
  return GetExamAttempts(repository);
}

class GetExamAttempts implements UseCase<List<ExamAttempt>, NoParams> {
  const GetExamAttempts(this._repository);

  final ExamAttemptRepository _repository;

  @override
  Future<Either<Failure, List<ExamAttempt>>> call(
    final NoParams params,
  ) async => _repository.getExamAttempts();
}
