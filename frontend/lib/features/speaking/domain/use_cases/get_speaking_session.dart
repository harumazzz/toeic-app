

import 'package:dart_either/dart_either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_cases/use_case.dart';
import '../../data/repositories/speaking_repository_impl.dart';
import '../entities/speaking.dart';
import '../repositories/speaking_repository.dart';

part 'get_speaking_session.freezed.dart';
part 'get_speaking_session.g.dart';

@riverpod
GetSpeakingSession getSpeakingSession(
  final Ref ref,
) {
  final repository = ref.watch(speakingRepositoryProvider);
  return GetSpeakingSession(repository);
}

class GetSpeakingSession implements 
UseCase<List<Speaking>, GetSpeakingSessionRequest> {

  const GetSpeakingSession(this.repository);

  final SpeakingRepository repository;

  @override
  Future<Either<Failure, List<Speaking>>> call(
    final GetSpeakingSessionRequest params,
  ) async => repository.getSpeakingSessions(
      userId: params.userId,
    );
}

@freezed
sealed class GetSpeakingSessionRequest with _$GetSpeakingSessionRequest {
  const factory GetSpeakingSessionRequest({
    required final int userId,
  }) = _GetSpeakingSessionRequest;
}
