import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/exam_repository_impl.dart';
import '../entities/exam.dart';
import '../repositories/exam_repository.dart';

part 'get_exam.freezed.dart';
part 'get_exam.g.dart';

@riverpod
GetExam getExam(final Ref ref) {
  final examRepository = ref.watch(examRepositoryProvider);
  return GetExam(examRepository: examRepository);
}

@riverpod
GetExams getExams(final Ref ref) {
  final examRepository = ref.watch(examRepositoryProvider);
  return GetExams(examRepository: examRepository);
}

class GetExam implements UseCase<Exam, int> {
  const GetExam({
    required this.examRepository,
  });

  final ExamRepository examRepository;

  @override
  Future<Either<Failure, Exam>> call(
    final int params,
  ) async => examRepository.getExamById(examId: params);
}

@freezed
abstract class GetExamsParams with _$GetExamsParams {
  const factory GetExamsParams({
    required final int limit,
    required final int offset,
  }) = _GetExamsParams;
}

class GetExams implements UseCase<List<Exam>, GetExamsParams> {
  const GetExams({
    required this.examRepository,
  });

  final ExamRepository examRepository;

  @override
  Future<Either<Failure, List<Exam>>> call(
    final GetExamsParams params,
  ) async => examRepository.getExams(
    limit: params.limit,
    offset: params.offset,
  );
}
