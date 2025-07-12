import 'package:freezed_annotation/freezed_annotation.dart';

part 'grammar.freezed.dart';

@freezed
abstract class Grammar with _$Grammar {
  const factory Grammar({
    final List<Content>? contents,
    required final String grammarKey,
    required final int id,
    required final int level,
    final List<int>? related,
    final List<String>? tag,
    required final String title,
  }) = _Grammar;
}

@freezed
abstract class Content with _$Content {
  const factory Content({
    final List<ContentElement>? content,
    final String? subTitle,
  }) = _Content;
}

@freezed
abstract class ContentElement with _$ContentElement {
  const factory ContentElement({
    final String? content,
    final List<Example>? examples,
    final List<String>? formulas,
  }) = _ContentElement;
}

@freezed
abstract class Example with _$Example {
  const factory Example({
    final String? example,
  }) = _Example;
}
