import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_answers_provider.g.dart';

@riverpod
class UserAnswers extends _$UserAnswers {
  @override
  Map<int, String> build() => {};

  void setAnswer(final int questionId, final String answer) {
    state = {...state, questionId: answer};
  }

  void removeAnswer(final int questionId) {
    final newState = Map<int, String>.from(state)..remove(questionId);
    state = newState;
  }

  void clearAllAnswers() {
    state = {};
  }
}

@riverpod
bool isQuestionAnswered(final Ref ref, final int questionId) {
  final answers = ref.watch(userAnswersProvider);
  return answers.containsKey(questionId);
}

@riverpod
String? getAnswer(final Ref ref, final int questionId) {
  final answers = ref.watch(userAnswersProvider);
  return answers[questionId];
}
