import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/speaking_repository_impl.dart';
import '../entities/speaking.dart';
import '../repositories/speaking_repository.dart';

part 'create_speaking_session.freezed.dart';
part 'create_speaking_session.g.dart';

@riverpod
CreateSpeakingSession createSpeakingSession(
  final Ref ref,
) {
  final repository = ref.watch(speakingRepositoryProvider);
  return CreateSpeakingSession(repository);
}

class CreateSpeakingSession
    implements UseCase<Speaking, CreateSpeakingSessionRequest> {
  const CreateSpeakingSession(this.repository);

  final SpeakingRepository repository;

  @override
  Future<Either<Failure, Speaking>> call(
    final CreateSpeakingSessionRequest params,
  ) async => repository.createSession(
    speakingRequest: params.speakingRequest,
  );
}

@freezed
abstract class CreateSpeakingSessionRequest
    with _$CreateSpeakingSessionRequest {
  const factory CreateSpeakingSessionRequest({
    required final SpeakingRequest speakingRequest,
  }) = _CreateSpeakingSessionRequest;
}
