import 'package:freezed_annotation/freezed_annotation.dart';

part 'word.freezed.dart';

@freezed
sealed class Word with _$Word {
  const factory Word({
    required final Conjugation conjugation,
    required final String descriptLevel,
    required final int freq,
    required final int id,
    required final int level,
    required final Conjugation means,
    required final String pronounce,
    required final String shortMean,
    required final Conjugation snym,
    required final String word,
  }) = _Word;
}

@freezed
sealed class Conjugation with _$Conjugation {
  const factory Conjugation({
    final String? raw,
  }) = _Conjugation;
}
