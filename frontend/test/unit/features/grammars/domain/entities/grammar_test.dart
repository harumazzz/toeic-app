import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/grammars/domain/entities/grammar.dart';

void main() {
  group('Grammar Entity', () {
    const tGrammar = Grammar(
      id: 1,
      title: 'Present Simple',
      grammarKey: 'present_simple',
      level: 2,
    );

    test('should create Grammar entity with correct values', () {
      // assert
      expect(tGrammar.id, 1);
      expect(tGrammar.title, 'Present Simple');
      expect(tGrammar.grammarKey, 'present_simple');
      expect(tGrammar.level, 2);
      expect(tGrammar.contents, isNull);
      expect(tGrammar.tag, isNull);
      expect(tGrammar.related, isNull);
    });

    test('should support equality comparison', () {
      // arrange
      const grammar1 = Grammar(
        id: 1,
        title: 'Present Simple',
        grammarKey: 'present_simple',
        level: 2,
      );

      const grammar2 = Grammar(
        id: 1,
        title: 'Present Simple',
        grammarKey: 'present_simple',
        level: 2,
      );

      // assert
      expect(grammar1, grammar2);
      expect(grammar1.hashCode, grammar2.hashCode);
    });

    test('should handle complex grammar with all fields', () {
      // arrange
      const example = Example(
        example: 'She goes to school everyday.',
      );

      const contentElement = ContentElement(
        content: 'This is a grammar explanation.',
        formulas: ['S + V(s/es) + O'],
        examples: [example],
      );

      const content = Content(
        subTitle: 'Usage',
        content: [contentElement],
      );

      const grammar = Grammar(
        id: 1,
        title: 'Present Simple',
        grammarKey: 'present_simple',
        level: 2,
        contents: [content],
        tag: ['basic', 'tense'],
        related: [2, 3],
      );

      // assert
      expect(grammar.contents, isNotNull);
      expect(grammar.contents!.length, 1);
      expect(grammar.contents!.first.subTitle, 'Usage');
      expect(grammar.contents!.first.content!.length, 1);
      expect(
        grammar.contents!.first.content!.first.content,
        'This is a grammar explanation.',
      );
      expect(grammar.tag, ['basic', 'tense']);
      expect(grammar.related, [2, 3]);
    });
  });

  group('Content Entity', () {
    test('should create Content with subtitle and content elements', () {
      // arrange
      const contentElement = ContentElement(
        content: 'This is a grammar explanation.',
      );

      const content = Content(
        subTitle: 'Usage',
        content: [contentElement],
      );

      // assert
      expect(content.subTitle, 'Usage');
      expect(content.content!.length, 1);
      expect(content.content!.first.content, 'This is a grammar explanation.');
    });

    test('should handle null content and subtitle', () {
      // arrange
      const content = Content();

      // assert
      expect(content.subTitle, isNull);
      expect(content.content, isNull);
    });
  });

  group('ContentElement Entity', () {
    test('should create ContentElement with all fields', () {
      // arrange
      const example = Example(
        example: 'She goes to school everyday.',
      );

      const contentElement = ContentElement(
        content: 'This is a grammar explanation.',
        formulas: ['S + V(s/es) + O'],
        examples: [example],
      );

      // assert
      expect(contentElement.content, 'This is a grammar explanation.');
      expect(contentElement.formulas!.length, 1);
      expect(contentElement.formulas!.first, 'S + V(s/es) + O');
      expect(contentElement.examples!.length, 1);
      expect(
        contentElement.examples!.first.example,
        'She goes to school everyday.',
      );
    });

    test('should handle null fields', () {
      // arrange
      const contentElement = ContentElement();

      // assert
      expect(contentElement.content, isNull);
      expect(contentElement.formulas, isNull);
      expect(contentElement.examples, isNull);
    });
  });

  group('Example Entity', () {
    test('should create Example with example text', () {
      // arrange
      const example = Example(
        example: 'She goes to school everyday.',
      );

      // assert
      expect(example.example, 'She goes to school everyday.');
    });

    test('should handle null example text', () {
      // arrange
      const example = Example();

      // assert
      expect(example.example, isNull);
    });
  });
}
