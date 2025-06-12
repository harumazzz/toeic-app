import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/word.dart';

part 'word_model.freezed.dart';
part 'word_model.g.dart';

@freezed
sealed class WordModel with _$WordModel {
  const factory WordModel({
    @Default(null)
    @JsonKey(name: 'conjugation')
    final ConjugationData? conjugation,
    @Default(null) @JsonKey(name: 'descript_level') final String? descriptLevel,
    @Default(null) @JsonKey(name: 'freq') final int? freq,
    @JsonKey(name: 'id') required final int id,
    @JsonKey(name: 'level') required final int level,
    @JsonKey(name: 'means') final List<MeaningData>? means,
    @JsonKey(name: 'pronounce') required final String pronounce,
    @JsonKey(name: 'short_mean') required final String shortMean,
    @JsonKey(name: 'snym') final List<SynonymData>? snym,
    @JsonKey(name: 'word') required final String word,
  }) = _WordModel;

  factory WordModel.fromJson(final Map<String, dynamic> json) =>
      _$WordModelFromJson(json);
}

@freezed
sealed class WordStateModel with _$WordStateModel {
  const factory WordStateModel({
    required final String p,
    required final String w,
  }) = _WordStateModel;

  factory WordStateModel.fromJson(final Map<String, dynamic> json) =>
      _$WordStateModelFromJson(json);
}

@freezed
sealed class SynonymData with _$SynonymData {
  const factory SynonymData({
    @JsonKey(name: 'kind') required final String kind,
    @JsonKey(name: 'content') required final List<ContentModel> content,
  }) = _SynonymData;

  factory SynonymData.fromJson(final Map<String, dynamic> json) =>
      _$SynonymDataFromJson(json);
}

@freezed
sealed class ContentModel with _$ContentModel {
  const factory ContentModel({
    @JsonKey(name: 'anto') final List<String>? antonym,
    @JsonKey(name: 'syno') final List<String>? synonym,
  }) = _ContentModel;

  factory ContentModel.fromJson(final Map<String, dynamic> json) =>
      _$ContentModelFromJson(json);
}

@freezed
sealed class MeaningData with _$MeaningData {
  const factory MeaningData({
    @JsonKey(name: 'kind') final String? kind,
    @JsonKey(name: 'means') final List<MeanModel>? means,
  }) = _MeaningData;

  factory MeaningData.fromJson(final Map<String, dynamic> json) =>
      _$MeaningDataFromJson(json);
}

@freezed
sealed class MeanModel with _$MeanModel {
  const factory MeanModel({
    @JsonKey(name: 'mean') final String? mean,
    @JsonKey(name: 'examples') final List<int>? examples,
  }) = _MeanModel;

  factory MeanModel.fromJson(final Map<String, dynamic> json) =>
      _$MeanModelFromJson(json);
}

@freezed
sealed class ConjugationData with _$ConjugationData {
  const factory ConjugationData({
    @JsonKey(name: 'htd') final WordStateModel? simplePresent,
    @JsonKey(name: 'qkd') final WordStateModel? simplePast,
    @JsonKey(name: 'htht') final WordStateModel? presentParticiple,
    @JsonKey(name: 'httd') final WordStateModel? presentContinuous,
  }) = _ConjugationData;

  factory ConjugationData.fromJson(final Map<String, dynamic> json) =>
      _$ConjugationDataFromJson(json);
}

extension WordModelExtension on WordModel {
  Word toEntity() => Word(
    conjugation: conjugation?.toEntity(),
    descriptLevel: descriptLevel,
    freq: freq,
    id: id,
    level: level,
    means: [...?means?.map((final e) => e.toEntity())],
    pronounce: pronounce,
    shortMean: shortMean,
    snym: [...?snym?.map((final e) => e.toEntity())],
    word: word,
  );
}

extension MeaningDataExtension on MeaningData {
  Meaning toEntity() => Meaning(
    kind: kind,
    means: [...?means?.map((final e) => e.toEntity())],
  );
}

extension MeanModelExtension on MeanModel {
  Mean toEntity() => Mean(
    mean: mean,
    examples: [...?examples],
  );
}

extension WordStateModelExtension on WordStateModel {
  WordState toEntity() => WordState(
    p: p,
    w: w,
  );
}

extension SynonymDataExtension on SynonymData {
  Synonym toEntity() => Synonym(
    kind: kind,
    content: [...content.map((final e) => e.toEntity())],
  );
}

extension ContentModelExtension on ContentModel {
  Content toEntity() => Content(
    antonym: antonym,
    synonym: synonym,
  );
}

extension ConjugationDataExtension on ConjugationData {
  Conjugation toEntity() => Conjugation(
    simplePresent: simplePresent?.toEntity(),
    simplePast: simplePast?.toEntity(),
    presentParticiple: presentParticiple?.toEntity(),
    presentContinuous: presentContinuous?.toEntity(),
  );
}
