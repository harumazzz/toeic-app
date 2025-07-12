import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/progress_repository_impl.dart';
import '../repositories/progress_repository.dart';

part 'delete_progress.g.dart';
part 'delete_progress.freezed.dart';

@riverpod
DeleteProgress deleteProgress(final Ref ref) {
  final progressRepository = ref.watch(progressRepositoryProvider);
  return DeleteProgress(progressRepository);
}

@freezed
abstract class DeleteProgressParams with _$DeleteProgressParams {
  const factory DeleteProgressParams({
    required final int wordId,
  }) = _DeleteProgressParams;
}

class DeleteProgress implements UseCase<Success, DeleteProgressParams> {
  const DeleteProgress(this._progressRepository);

  final ProgressRepository _progressRepository;

  @override
  Future<Either<Failure, Success>> call(
    final DeleteProgressParams params,
  ) => _progressRepository.deleteProgress(
    wordId: params.wordId,
  );
}
