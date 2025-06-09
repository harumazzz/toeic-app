import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/progress_repository_impl.dart';
import '../entities/progress.dart';
import '../repositories/progress_repository.dart';

part 'update_progress.g.dart';
part 'update_progress.freezed.dart';

@riverpod
UpdateProgress updateProgress(final Ref ref) {
  final progressRepository = ref.watch(progressRepositoryProvider);
  return UpdateProgress(progressRepository);
}

@freezed
sealed class UpdateProgressParams with _$UpdateProgressParams {
  const factory UpdateProgressParams({
    required final int wordId,
    required final WordProgressRequest request,
  }) = _UpdateProgressParams;
}

class UpdateProgress implements UseCase<WordProgress, UpdateProgressParams> {

  const UpdateProgress(this._progressRepository);

  final ProgressRepository _progressRepository;

  @override
  Future<Either<Failure, WordProgress>> call(
    final UpdateProgressParams params,
  ) => _progressRepository.updateProgress(
    wordId: params.wordId,
    request: params.request,
  );
  
}
