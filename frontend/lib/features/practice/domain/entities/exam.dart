import 'package:freezed_annotation/freezed_annotation.dart';

part 'exam.freezed.dart';

@freezed
abstract class Exam with _$Exam {
  const factory Exam({
    required final int examId,
    required final int timeLimitMinutes,
    required final String title,
  }) = _Exam;
}
