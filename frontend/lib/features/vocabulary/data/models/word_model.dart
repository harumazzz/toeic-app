import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/word.dart';

part 'word_model.freezed.dart';
part 'word_model.g.dart';

@freezed
sealed class WordModel with _$WordModel {
  const factory WordModel({
    @JsonKey(name: 'conjugation') required final ConjugationModel conjugation,
    @JsonKey(name: 'descript_level') required final String descriptLevel,
    @JsonKey(name: 'freq') required final int freq,
    @JsonKey(name: 'id') required final int id,
    @JsonKey(name: 'level') required final int level,
    @JsonKey(name: 'means') required final ConjugationModel means,
    @JsonKey(name: 'pronounce') required final String pronounce,
    @JsonKey(name: 'short_mean') required final String shortMean,
    @JsonKey(name: 'snym') required final ConjugationModel snym,
    @JsonKey(name: 'word') required final String word,
  }) = _WordModel;

  factory WordModel.fromJson(final Map<String, dynamic> json) =>
      _$WordModelFromJson(json);
}

@freezed
sealed class ConjugationModel with _$ConjugationModel {
  const factory ConjugationModel({
    @JsonKey(name: 'raw') final String? raw,
  }) = _ConjugationModel;

  factory ConjugationModel.fromJson(final Map<String, dynamic> json) =>
      _$ConjugationModelFromJson(json);
}

extension WordModelExtension on WordModel {
  Word toEntity() => Word(
    conjugation: conjugation.toEntity(),
    descriptLevel: descriptLevel,
    freq: freq,
    id: id,
    level: level,
    means: means.toEntity(),
    pronounce: pronounce,
    shortMean: shortMean,
    snym: snym.toEntity(),
    word: word,
  );
}

extension ConjugationModelExtension on ConjugationModel {
  Conjugation toEntity() => Conjugation(
    raw: raw,
  );
}
