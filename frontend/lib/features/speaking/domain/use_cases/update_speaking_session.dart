

import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/speaking_repository_impl.dart';
import '../entities/speaking.dart';
import '../repositories/speaking_repository.dart';

part 'update_speaking_session.g.dart';
part 'update_speaking_session.freezed.dart';

@riverpod
UpdateSpeakingSession updateSpeakingSession(
  final Ref ref,
) {
  final repository = ref.watch(speakingRepositoryProvider);
  return UpdateSpeakingSession(repository);
}

class UpdateSpeakingSession implements 
UseCase<Speaking, UpdateSpeakingSessionRequest> {

  const UpdateSpeakingSession(this.repository);

  final SpeakingRepository repository;

  @override
  Future<Either<Failure, Speaking>> call(
    final UpdateSpeakingSessionRequest params,
  ) async => repository.updateSession(
    id: params.id,
    speakingRequest: params.speakingRequest,
  );
}

@freezed
sealed class UpdateSpeakingSessionRequest with _$UpdateSpeakingSessionRequest {
  const factory UpdateSpeakingSessionRequest({
    required final int id,
    required final SpeakingRequest speakingRequest,
  }) = _UpdateSpeakingSessionRequest;
}
