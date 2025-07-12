import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/content.dart';

part 'content_model.g.dart';
part 'content_model.freezed.dart';

@freezed
abstract class ContentModel with _$ContentModel {
  const factory ContentModel({
    @JsonKey(name: 'content_id') required final int contentId,
    @JsonKey(name: 'description') required final String description,
    @JsonKey(name: 'part_id') required final int partId,
    @JsonKey(name: 'type') required final String type,
  }) = _ContentModel;

  factory ContentModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$ContentModelFromJson(json);
}

extension ContentModelExtension on ContentModel {
  Content toEntity() => Content(
    contentId: contentId,
    description: description,
    partId: partId,
    type: type,
  );
}
