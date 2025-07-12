import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/speaking_repository_impl.dart';
import '../entities/speaking.dart';
import '../repositories/speaking_repository.dart';

part 'get_speaking_session_by_id.freezed.dart';
part 'get_speaking_session_by_id.g.dart';

@riverpod
GetSpeakingSessionById getSpeakingSessionById(
  final Ref ref,
) {
  final repository = ref.watch(speakingRepositoryProvider);
  return GetSpeakingSessionById(repository);
}

class GetSpeakingSessionById
    implements UseCase<Speaking, GetSpeakingSessionByIdRequest> {
  const GetSpeakingSessionById(this.repository);

  final SpeakingRepository repository;

  @override
  Future<Either<Failure, Speaking>> call(
    final GetSpeakingSessionByIdRequest params,
  ) async => repository.getSessionById(
    id: params.id,
  );
}

@freezed
abstract class GetSpeakingSessionByIdRequest
    with _$GetSpeakingSessionByIdRequest {
  const factory GetSpeakingSessionByIdRequest({
    required final int id,
  }) = _GetSpeakingSessionByIdRequest;
}
