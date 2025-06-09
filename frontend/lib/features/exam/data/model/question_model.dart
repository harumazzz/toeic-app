import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/question.dart';

part 'question_model.freezed.dart';
part 'question_model.g.dart';

@freezed
sealed class QuestionModel with _$QuestionModel {
    const factory QuestionModel({
        @JsonKey(name: 'content_id')
        required final int contentId,
        @JsonKey(name: 'explanation')
        required final String explanation,
        @JsonKey(name: 'image_url')
        required final String imageUrl,
        @JsonKey(name: 'keywords')
        required final String keywords,
        @JsonKey(name: 'media_url')
        required final String mediaUrl,
        @JsonKey(name: 'possible_answers')
        required final List<String> possibleAnswers,
        @JsonKey(name: 'question_id')
        required final int questionId,
        @JsonKey(name: 'title')
        required final String title,
        @JsonKey(name: 'true_answer')
        required final String trueAnswer,
    }) = _QuestionModel;

    factory QuestionModel.fromJson(
      final Map<String, dynamic> json,
    ) => _$QuestionModelFromJson(json);
}

extension QuestionModelExtension on QuestionModel {

  Question toEntity() => Question(
    contentId: contentId, 
    questionId: questionId, 
    explanation: explanation, 
    imageUrl: imageUrl, 
    keywords: keywords, 
    mediaUrl: mediaUrl, 
    possibleAnswers: possibleAnswers, 
    title: title, 
    trueAnswer: trueAnswer,
  );

}
