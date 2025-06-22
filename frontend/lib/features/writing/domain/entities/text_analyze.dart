import 'package:freezed_annotation/freezed_annotation.dart';

part 'text_analyze.freezed.dart';

@freezed
sealed class TextAnalyzeRequest with _$TextAnalyzeRequest {
    const factory TextAnalyzeRequest({
        required final String minSynonymLevel,
        required final String text,
    }) = _TextAnalyzeRequest;
}

@freezed
sealed class TextAnalyze with _$TextAnalyze {
    const factory TextAnalyze({
        required final String error,
        required final Result result,
        required final String text,
        required final String timestamp,
        required final int userId,
    }) = _TextAnalyze;
}

@freezed
sealed class Result with _$Result {
    const factory Result({
        required final List<Word> words,
    }) = _Result;
}

@freezed
sealed class Word with _$Word {
    const factory Word({
        required final int count,
        required final String level,
        required final List<Suggestion> suggestions,
        required final String word,
    }) = _Word;
}

@freezed
sealed class Suggestion with _$Suggestion {
    const factory Suggestion({
        required final String definition,
        required final String level,
        required final String word,
    }) = _Suggestion;
}
