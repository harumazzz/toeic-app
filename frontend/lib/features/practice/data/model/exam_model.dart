import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/exam.dart';

part 'exam_model.freezed.dart';
part 'exam_model.g.dart';

@freezed
abstract class ExamModel with _$ExamModel {
  const factory ExamModel({
    @JsonKey(name: 'exam_id') required final int examId,
    @JsonKey(name: 'time_limit_minutes') required final int timeLimitMinutes,
    @JsonKey(name: 'title') required final String title,
  }) = _ExamModel;

  factory ExamModel.fromJson(final Map<String, dynamic> json) =>
      _$ExamModelFromJson(json);
}

extension ExamModelExtension on ExamModel {
  Exam toEntity() => Exam(
    examId: examId,
    timeLimitMinutes: timeLimitMinutes,
    title: title,
  );
}
