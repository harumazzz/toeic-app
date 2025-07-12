import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/speaking_repository_impl.dart';
import '../repositories/speaking_repository.dart';

part 'delete_speaking_session.freezed.dart';
part 'delete_speaking_session.g.dart';

@riverpod
DeleteSpeakingSession deleteSpeakingSession(
  final Ref ref,
) {
  final repository = ref.watch(speakingRepositoryProvider);
  return DeleteSpeakingSession(repository);
}

class DeleteSpeakingSession
    implements UseCase<Success, DeleteSpeakingSessionRequest> {
  const DeleteSpeakingSession(this.repository);

  final SpeakingRepository repository;

  @override
  Future<Either<Failure, Success>> call(
    final DeleteSpeakingSessionRequest params,
  ) async => repository.deleteSession(
    id: params.id,
  );
}

@freezed
abstract class DeleteSpeakingSessionRequest
    with _$DeleteSpeakingSessionRequest {
  const factory DeleteSpeakingSessionRequest({
    required final int id,
  }) = _DeleteSpeakingSessionRequest;
}
