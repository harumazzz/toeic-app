import 'package:freezed_annotation/freezed_annotation.dart';

import 'writing_feedback.dart';

part 'user_writing.freezed.dart';

@freezed
abstract class UserWriting with _$UserWriting {
  const factory UserWriting({
    required final int id,
    required final int userId,
    final int? promptId,
    required final String submissionText,
    final WritingFeedback? aiFeedback,
    final double? aiScore,
    required final DateTime submittedAt,
    final DateTime? evaluatedAt,
    required final DateTime updatedAt,
  }) = _UserWriting;
}

@freezed
abstract class UserWritingRequest with _$UserWritingRequest {
  const factory UserWritingRequest({
    required final int userId,
    final int? promptId,
    required final String submissionText,
    final WritingFeedback? aiFeedback,
    final double? aiScore,
  }) = _UserWritingRequest;
}

@freezed
abstract class UserWritingUpdateRequest with _$UserWritingUpdateRequest {
  const factory UserWritingUpdateRequest({
    final String? submissionText,
    final WritingFeedback? aiFeedback,
    final double? aiScore,
    final DateTime? evaluatedAt,
  }) = _UserWritingUpdateRequest;
}
