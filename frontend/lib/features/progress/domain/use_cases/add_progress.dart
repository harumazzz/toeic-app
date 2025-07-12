import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/progress_repository_impl.dart';
import '../entities/progress.dart';
import '../repositories/progress_repository.dart';

part 'add_progress.g.dart';
part 'add_progress.freezed.dart';

@riverpod
AddProgress addProgress(final Ref ref) {
  final progressRepository = ref.watch(progressRepositoryProvider);
  return AddProgress(progressRepository);
}

@freezed
abstract class AddProgressParams with _$AddProgressParams {
  const factory AddProgressParams({
    required final WordProgressRequest request,
  }) = _AddProgressParams;
}

class AddProgress implements UseCase<WordProgress, AddProgressParams> {
  const AddProgress(this._progressRepository);

  final ProgressRepository _progressRepository;

  @override
  Future<Either<Failure, WordProgress>> call(
    final AddProgressParams params,
  ) => _progressRepository.addNewProgress(
    request: params.request,
  );
}
