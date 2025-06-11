import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/grammar.dart';

part 'grammar_model.freezed.dart';
part 'grammar_model.g.dart';

@freezed
sealed class GrammarModel with _$GrammarModel {
  const factory GrammarModel({
    @JsonKey(name: 'contents') final List<ContentModel>? contents,
    @JsonKey(name: 'grammar_key') required final String grammarKey,
    @JsonKey(name: 'id') required final int id,
    @JsonKey(name: 'level') required final int level,
    @JsonKey(name: 'related') final List<int>? related,
    @JsonKey(name: 'tag') final List<String>? tag,
    @JsonKey(name: 'title') required final String title,
  }) = _GrammarModel;

  factory GrammarModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$GrammarModelFromJson(json);
}

@freezed
sealed class ContentModel with _$ContentModel {
  const factory ContentModel({
    @JsonKey(name: 'content') final List<ContentElementModel>? content,
    @JsonKey(name: 'sub_title') final String? subTitle,
  }) = _ContentModel;

  factory ContentModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$ContentModelFromJson(json);
}

@freezed
sealed class ContentElementModel with _$ContentElementModel {
  const factory ContentElementModel({
    @JsonKey(name: 'c') final String? content,
    @JsonKey(name: 'e') final List<ExampleModel>? examples,
    @JsonKey(name: 'f') final List<String>? formulas,
  }) = _ContentElementModel;

  factory ContentElementModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$ContentElementModelFromJson(json);
}

@freezed
sealed class ExampleModel with _$ExampleModel {
  const factory ExampleModel({
    @JsonKey(name: 'e') final String? example,
  }) = _ExampleModel;

  factory ExampleModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$ExampleModelFromJson(json);
}

@freezed
sealed class GetRelatedGrammarsRequest with _$GetRelatedGrammarsRequest {
  const factory GetRelatedGrammarsRequest({
    @JsonKey(name: 'ids') required final List<int> ids,
  }) = _GetRelatedGrammarsRequest;

  factory GetRelatedGrammarsRequest.fromJson(
    final Map<String, dynamic> json,
  ) => _$GetRelatedGrammarsRequestFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

extension GrammarModelExtension on GrammarModel {
  Grammar toEntity() => Grammar(
    contents: [...?contents?.map((final e) => e.toEntity())],
    grammarKey: grammarKey,
    id: id,
    level: level,
    related: related,
    tag: tag,
    title: title,
  );
}

extension ContentModelExtension on ContentModel {
  Content toEntity() => Content(
    content: [...?content?.map((final e) => e.toEntity())],
    subTitle: subTitle,
  );
}

extension ContentElementModelExtension on ContentElementModel {
  ContentElement toEntity() => ContentElement(
    content: content,
    examples: [...?examples?.map((final e) => e.toEntity())],
    formulas: formulas,
  );
}

extension ExampleModelExtension on ExampleModel {
  Example toEntity() => Example(
    example: example,
  );
}
