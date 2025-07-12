import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/speaking_repository_impl.dart';
import '../entities/speaking.dart';
import '../repositories/speaking_repository.dart';

part 'create_speaking_turn.freezed.dart';
part 'create_speaking_turn.g.dart';

@riverpod
CreateSpeakingTurn createSpeakingTurn(
  final Ref ref,
) {
  final repository = ref.watch(speakingRepositoryProvider);
  return CreateSpeakingTurn(repository);
}

class CreateSpeakingTurn
    implements UseCase<SpeakingTurn, CreateSpeakingTurnRequest> {
  const CreateSpeakingTurn(this.repository);

  final SpeakingRepository repository;

  @override
  Future<Either<Failure, SpeakingTurn>> call(
    final CreateSpeakingTurnRequest params,
  ) async => repository.createNewTurn(
    request: params.speakingTurnRequest,
  );
}

@freezed
abstract class CreateSpeakingTurnRequest with _$CreateSpeakingTurnRequest {
  const factory CreateSpeakingTurnRequest({
    required final SpeakingTurnRequest speakingTurnRequest,
  }) = _CreateSpeakingTurnRequest;
}
