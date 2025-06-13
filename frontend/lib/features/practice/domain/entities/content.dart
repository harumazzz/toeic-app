import 'package:freezed_annotation/freezed_annotation.dart';

part 'content.freezed.dart';

@freezed
sealed class Content with _$Content {
    const factory Content({
      required final int contentId,
      required final String description,
      required final int partId,
      required final String type,
    }) = _Content;
}
