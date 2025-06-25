import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/speaking.dart';
import '../../domain/use_cases/get_speaking_session.dart';

part 'speaking_provider.freezed.dart';
part 'speaking_provider.g.dart';

@freezed
sealed class SpeakingState with _$SpeakingState {
  const factory SpeakingState.initial() = SpeakingStateInitial;

  const factory SpeakingState.loading() = SpeakingStateLoading;

  const factory SpeakingState.loaded({
    required final List<Speaking> sessions,
  }) = SpeakingStateLoaded;

  const factory SpeakingState.error({
    required final String message,
  }) = SpeakingStateError;
}

@riverpod
class SpeakingSessions extends _$SpeakingSessions {
  @override
  SpeakingState build() => const SpeakingState.initial();

  Future<void> loadSessions() async {
    if (state is SpeakingStateLoading) {
      return;
    }
    final authProvider = ref.watch(authControllerProvider);
    if (authProvider is! AuthAuthenticated) {
      return;
    }
    state = const SpeakingState.loading();
    final useCase = ref.watch(getSpeakingSessionProvider);
    final userId = authProvider.user.id;
    final result = await useCase.call(
      GetSpeakingSessionRequest(
        userId: userId,
      ),
    );
    result.fold(
      ifLeft:
          (final failure) =>
              state = SpeakingState.error(message: failure.message),
      ifRight:
          (final sessions) => state = SpeakingState.loaded(sessions: sessions),
    );
  }

  Future<void> refresh() async {
    if (state is SpeakingStateLoading) {
      return;
    }
    final authProvider = ref.watch(authControllerProvider);
    if (authProvider is! AuthAuthenticated) {
      return;
    }
    state = const SpeakingState.loading();
    final useCase = ref.watch(getSpeakingSessionProvider);
    final userId = authProvider.user.id;
    final result = await useCase.call(
      GetSpeakingSessionRequest(userId: userId),
    );
    result.fold(
      ifLeft:
          (final failure) =>
              state = SpeakingState.error(message: failure.message),
      ifRight:
          (final sessions) => state = SpeakingState.loaded(sessions: sessions),
    );
  }
}
