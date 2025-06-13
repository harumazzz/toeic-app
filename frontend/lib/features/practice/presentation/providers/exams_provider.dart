import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/exam.dart';
import '../../domain/use_cases/get_exam.dart';

part 'exams_provider.freezed.dart';
part 'exams_provider.g.dart';

@freezed
sealed class ExamsState with _$ExamsState {
  const factory ExamsState.initial() = ExamInitial;
  const factory ExamsState.loading({
    required final List<Exam> exams,
  }) = ExamLoading;
  const factory ExamsState.loaded({
    required final List<Exam> exams,
    required final bool hasMore,
  }) = ExamLoaded;
  const factory ExamsState.error({
    required final List<Exam> exams,
    required final String message,
  }) = ExamError;
}

@Riverpod(keepAlive: true)
class ExamsNotifier extends _$ExamsNotifier {
  @override
  ExamsState build() => const ExamsState.initial();

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is ExamLoading ||
        (currentState is ExamLoaded && !currentState.hasMore)) {
      return;
    }

    final currentExams = switch (currentState) {
      ExamInitial() => <Exam>[],
      ExamLoading(exams: final exams) => exams,
      ExamLoaded(exams: final exams) => exams,
      ExamError(exams: final exams) => exams,
    };

    state = ExamsState.loading(exams: currentExams);

    final getExams = ref.read(getExamsProvider);
    final result = await getExams(
      GetExamsParams(
        limit: 10,
        offset: currentExams.length ~/ 10,
      ),
    );

    result.fold(
      ifLeft: (final failure) {
        state = ExamsState.error(
          exams: currentExams,
          message: failure.message,
        );
      },
      ifRight: (final newExams) {
        final updatedExams = [...currentExams, ...newExams];
        state = ExamsState.loaded(
          exams: updatedExams,
          hasMore: newExams.length == 10,
        );
      },
    );
  }

  Future<void> refresh() async {
    state = const ExamsState.initial();
    await loadMore();
  }
}
