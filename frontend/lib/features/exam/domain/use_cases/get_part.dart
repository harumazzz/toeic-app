import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/part_repository_impl.dart';
import '../entities/part.dart';
import '../repositories/part_repository.dart';

part 'get_part.freezed.dart';
part 'get_part.g.dart';

@riverpod
GetPart getPart(final Ref ref) {
  final repository = ref.watch(partRepositoryProvider);
  return GetPart(repository);
}

@riverpod
GetPartsByExam getPartsByExam(final Ref ref) {
  final repository = ref.watch(partRepositoryProvider);
  return GetPartsByExam(repository);
}

@freezed
sealed class GetPartParams with _$GetPartParams {
  const factory GetPartParams({
    required final int partId,
  }) = _GetPartParams;
}

@freezed
sealed class GetPartsByExamParams with _$GetPartsByExamParams {
  const factory GetPartsByExamParams({
    required final int examId,
  }) = _GetPartsByExamParams;
}

class GetPart implements UseCase<Part, GetPartParams> {

  const GetPart(this._partRepository);

  final PartRepository _partRepository;

  @override
  Future<Either<Failure, Part>> call(
    final GetPartParams params
  ) => _partRepository.getPartById(
    partId: params.partId,
  );

}

class GetPartsByExam implements UseCase<List<Part>, GetPartsByExamParams> {

  const GetPartsByExam(this._partRepository);

  final PartRepository _partRepository;

  @override
  Future<Either<Failure, List<Part>>> call(
    final GetPartsByExamParams params
  ) => _partRepository.getPartsByExamId(
    examId: params.examId,
  );

}
