import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/exam.dart';
import '../../domain/usecases/create_exam_attempt.dart';

part 'attempt_provider.freezed.dart';
part 'attempt_provider.g.dart';

@freezed
sealed class AttemptState with _$AttemptState {
  const factory AttemptState.initial() = AttemptInitial;
  const factory AttemptState.loading() = AttemptLoading;
  const factory AttemptState.loaded(
    final List<ExamAttempt> attempts,
  ) = AttemptLoaded;
  const factory AttemptState.started(
    final ExamAttempt attempt,
  ) = AttemptStarted;
  const factory AttemptState.error(final String message) = AttemptError;
}

@Riverpod(keepAlive: true)
class AttemptNotifier extends _$AttemptNotifier {
  @override
  AttemptState build() => const AttemptState.initial();
  Future<void> startExamAttempt(final int examId) async {
    if (state is AttemptLoading) {
      return;
    }
    final authState = ref.read(authControllerProvider);
    if (authState is! AuthAuthenticated) {
      state = const AttemptState.error(
        'User must be logged in to start an exam',
      );
      return;
    }
    state = const AttemptState.loading();

    try {
      final createExamAttemptUseCase = ref.read(createExamAttemptProvider);
      final result = await createExamAttemptUseCase(
        CreateExamAttemptParams(
          examAttempt: ExamRequest(examId: examId),
        ),
      );
      result.fold(
        ifLeft: (final failure) => state = AttemptState.error(failure.message),
        ifRight: (final attempt) => state = AttemptState.started(attempt),
      );
    } catch (e) {
      state = AttemptState.error('Failed to start exam: $e');
    }
  }

  Future<void> submitAttempts(final int examId) async {
    if (state is AttemptLoading) {
      return;
    }
    state = const AttemptState.loading();
  }
}
