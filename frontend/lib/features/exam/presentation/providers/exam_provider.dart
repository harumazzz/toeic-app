import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/exam.dart';
import '../../domain/usecases/get_exam_questions.dart';

part 'exam_provider.g.dart';
part 'exam_provider.freezed.dart';

@freezed
sealed class ExamState with _$ExamState {
  const factory ExamState.initial() = ExamInitial;
  const factory ExamState.loading() = ExamLoading;
  const factory ExamState.loaded(final Exam exam) = ExamLoaded;
  const factory ExamState.error(final String message) = ExamError;
}

@riverpod
class ExamNotifier extends _$ExamNotifier {
  @override
  ExamState build() => const ExamState.initial();

  Future<void> loadExam(final int examId) async {
    state = const ExamState.loading();
    final getExamQuestions = ref.read(getExamQuestionsProvider);
    final result = await getExamQuestions(
      GetExamQuestionsParams(examId: examId),
    );
    result.fold(
      ifLeft: (final failure) => state = ExamState.error(failure.message),
      ifRight: (final exam) => state = ExamState.loaded(exam),
    );
  }
}
