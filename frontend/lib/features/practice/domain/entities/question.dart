import 'package:freezed_annotation/freezed_annotation.dart';

part 'question.freezed.dart';

@freezed
sealed class Question with _$Question {
  const factory Question({
    required final int contentId,
    required final int questionId,
    required final String explanation,
    final String? imageUrl,
    final String? keywords,
    final String? mediaUrl,
    required final List<String> possibleAnswers,
    required final String title,
    required final String trueAnswer,
  }) = _Question;
}
