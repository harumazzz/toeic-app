import 'package:freezed_annotation/freezed_annotation.dart';

part 'part.freezed.dart';

@freezed
abstract class Part with _$Part {
  const factory Part({
    required final int examId,
    required final int partId,
    required final String title,
  }) = _Part;
}
