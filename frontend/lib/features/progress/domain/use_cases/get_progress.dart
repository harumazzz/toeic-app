import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/progress_repository_impl.dart';
import '../entities/progress.dart';
import '../repositories/progress_repository.dart';

part 'get_progress.g.dart';
part 'get_progress.freezed.dart';

@riverpod
GetReviewsProgress getReviewsProgress(final Ref ref) {
  final progressRepository = ref.watch(progressRepositoryProvider);
  return GetReviewsProgress(progressRepository);
}

@riverpod
GetWorkProgress getWorkProgress(final Ref ref) {
  final progressRepository = ref.watch(progressRepositoryProvider);
  return GetWorkProgress(progressRepository);
}

@riverpod
GetProgress getProgress(final Ref ref) {
  final progressRepository = ref.watch(progressRepositoryProvider);
  return GetProgress(progressRepository);
}

@freezed
sealed class GetReviewsProgressParams with _$GetReviewsProgressParams {
  const factory GetReviewsProgressParams({
    required final int limit,
  }) = _GetReviewsProgressParams;
}

@freezed
sealed class GetWordProgressParams with _$GetWordProgressParams {
  const factory GetWordProgressParams({
    required final int wordId,
  }) = _GetWordProgressParams;
}

@freezed
sealed class GetProgressParams with _$GetProgressParams {
  const factory GetProgressParams({
    required final int wordId,
  }) = _GetProgressParams;
}

class GetReviewsProgress implements 
UseCase<List<WordProgress>, GetReviewsProgressParams> {

  const GetReviewsProgress(this._progressRepository);

  final ProgressRepository _progressRepository;

  @override
  Future<Either<Failure, List<WordProgress>>> call(
    final GetReviewsProgressParams params,
  ) => _progressRepository.getReviewsProgress(
    limit: params.limit,
  );
}

class GetWorkProgress implements UseCase<WordProgress, GetWordProgressParams> {

  const GetWorkProgress(this._progressRepository);

  final ProgressRepository _progressRepository;

  @override
  Future<Either<Failure, WordProgress>> call(
    final GetWordProgressParams params,
  ) => _progressRepository.getWordProgressById(
    wordId: params.wordId,
  );
  
}

class GetProgress implements UseCase<Progress, GetProgressParams> {

  const GetProgress(this._progressRepository);

  final ProgressRepository _progressRepository;

  @override
  Future<Either<Failure, Progress>> call(
    final GetProgressParams params,
  ) => _progressRepository.getProgressById(
    wordId: params.wordId,
  );
  
}
