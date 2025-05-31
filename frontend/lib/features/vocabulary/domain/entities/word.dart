import 'package:freezed_annotation/freezed_annotation.dart';

part 'word.freezed.dart';

@freezed
sealed class Word with _$Word {
  const factory Word({
    final Conjugation? conjugation,
    required final String descriptLevel,
    required final int freq,
    required final int id,
    required final int level,
    final List<Meaning>? means,
    required final String pronounce,
    required final String shortMean,
    final List<Synonym>? snym,
    required final String word,
  }) = _Word;
}

@freezed
sealed class WordState with _$WordState {
  const factory WordState({
    required final String? p,
    required final String? w,
  }) = _WordState;
}

@freezed
sealed class Conjugation with _$Conjugation {
  const factory Conjugation({
    final WordState? simplePresent,
    final WordState? simplePast,
    final WordState? presentContinuous,
    final WordState? presentParticiple,
  }) = _Conjugation;
}

@freezed
sealed class Synonym with _$Synonym {
  const factory Synonym({
    required final String? kind,
    required final List<Content>? content,
  }) = _Synonym;
}

@freezed
sealed class Content with _$Content {
  const factory Content({
    required final List<String>? antonym,
    required final List<String>? synonym,
  }) = _Content;
}

@freezed
sealed class Meaning with _$Meaning {
  const factory Meaning({
    required final String? kind,
    required final List<Mean>? means,
  }) = _Meaning;
}

@freezed
sealed class Mean with _$Mean {
  const factory Mean({
    required final String? mean,
    required final List<int>? examples,
  }) = _Mean;
}
