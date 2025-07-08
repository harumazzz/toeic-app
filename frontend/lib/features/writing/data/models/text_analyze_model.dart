import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/text_analyze.dart';

part 'text_analyze_model.freezed.dart';
part 'text_analyze_model.g.dart';

@freezed
sealed class TextAnalyzeRequestModel with _$TextAnalyzeRequestModel {
  const factory TextAnalyzeRequestModel({
    @JsonKey(name: 'async') required final bool textAnalyzeRequestModelAsync,
    @JsonKey(name: 'min_synonym_level') required final String minSynonymLevel,
    @JsonKey(name: 'text') required final String text,
  }) = _TextAnalyzeRequestModel;

  factory TextAnalyzeRequestModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$TextAnalyzeRequestModelFromJson(json);

  @override
  Map<String, dynamic> toJson();
}

Map<String, dynamic> serializeTextAnalyzeRequestModel(
  final TextAnalyzeRequestModel object,
) => object.toJson();

@freezed
sealed class TextAnalyzeModel with _$TextAnalyzeModel {
  const factory TextAnalyzeModel({
    @JsonKey(name: 'cached') required final bool? cached,
    @JsonKey(name: 'error') required final String? error,
    @JsonKey(name: 'result') required final ResultModel result,
    @JsonKey(name: 'text') required final String text,
    @JsonKey(name: 'timestamp') required final String timestamp,
    @JsonKey(name: 'user_id') required final int userId,
  }) = _TextAnalyzeModel;

  factory TextAnalyzeModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$TextAnalyzeModelFromJson(json);
}

@freezed
sealed class ResultModel with _$ResultModel {
  const factory ResultModel({
    @JsonKey(name: 'words') required final List<WordModel> words,
  }) = _ResultModel;

  factory ResultModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$ResultModelFromJson(json);
}

@freezed
sealed class WordModel with _$WordModel {
  const factory WordModel({
    @JsonKey(name: 'count') required final int count,
    @JsonKey(name: 'level') required final String level,
    @JsonKey(name: 'suggestions') final List<SuggestionModel>? suggestions,
    @JsonKey(name: 'word') required final String word,
  }) = _WordModel;

  factory WordModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$WordModelFromJson(json);
}

@freezed
sealed class SuggestionModel with _$SuggestionModel {
  const factory SuggestionModel({
    @JsonKey(name: 'definition') required final String definition,
    @JsonKey(name: 'level') required final String level,
    @JsonKey(name: 'word') required final String word,
  }) = _SuggestionModel;

  factory SuggestionModel.fromJson(
    final Map<String, dynamic> json,
  ) => _$SuggestionModelFromJson(json);
}

extension TextAnalyzeRequestExtension on TextAnalyzeRequest {
  TextAnalyzeRequestModel toModel() => TextAnalyzeRequestModel(
    textAnalyzeRequestModelAsync: false,
    minSynonymLevel: minSynonymLevel,
    text: text,
  );
}

extension TextAnalyzeExtension on TextAnalyzeModel {
  TextAnalyze toEntity() => TextAnalyze(
    error: error,
    result: result.toEntity(),
    text: text,
    timestamp: timestamp,
    userId: userId,
  );
}

extension ResultExtension on ResultModel {
  Result toEntity() => Result(
    words: [...words.map((final word) => word.toEntity())],
  );
}

extension WordExtension on WordModel {
  Word toEntity() => Word(
    count: count,
    level: level,
    suggestions: suggestions?.map((final e) => e.toEntity()).toList(),
    word: word,
  );
}

extension SuggestionExtension on SuggestionModel {
  Suggestion toEntity() => Suggestion(
    definition: definition,
    level: level,
    word: word,
  );
}
