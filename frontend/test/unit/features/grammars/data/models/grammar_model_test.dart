import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/grammars/data/models/grammar_model.dart';
import 'package:learn/features/grammars/domain/entities/grammar.dart';

void main() {
  group('GrammarModel', () {
    const tGrammarModel = GrammarModel(
      id: 1,
      title: 'Present Simple',
      grammarKey: 'present_simple',
      level: 2,
    );

    const tGrammar = Grammar(
      id: 1,
      title: 'Present Simple',
      grammarKey: 'present_simple',
      level: 2,
      contents: [],
    );

    test('should be a subclass of Grammar entity', () async {
      // assert
      expect(tGrammarModel.toEntity(), isA<Grammar>());
    });

    test('should convert from JSON correctly', () async {
      // arrange
      final jsonMap = {
        'id': 1,
        'title': 'Present Simple',
        'grammar_key': 'present_simple',
        'level': 2,
      };

      // act
      final result = GrammarModel.fromJson(jsonMap);

      // assert
      expect(result, tGrammarModel);
    });

    test('should convert to JSON correctly', () async {
      // arrange
      final expectedJson = {
        'id': 1,
        'title': 'Present Simple',
        'grammar_key': 'present_simple',
        'level': 2,
        'contents': null,
        'related': null,
        'tag': null,
      };

      // act
      final result = tGrammarModel.toJson();

      // assert
      expect(result, expectedJson);
    });

    test('should convert to entity correctly', () async {
      // act
      final result = tGrammarModel.toEntity();

      // assert
      expect(result, tGrammar);
      expect(result.id, 1);
      expect(result.title, 'Present Simple');
      expect(result.grammarKey, 'present_simple');
      expect(result.level, 2);
      expect(result.contents, isEmpty);
      expect(result.tag, isNull);
      expect(result.related, isNull);
    });

    test('should handle complex grammar model with all fields', () async {
      // arrange
      const contentElementModel = ContentElementModel(
        content: 'This is a grammar explanation.',
        formulas: ['S + V(s/es) + O'],
        examples: [
          ExampleModel(example: 'She goes to school everyday.'),
        ],
      );

      const contentModel = ContentModel(
        subTitle: 'Usage',
        content: [contentElementModel],
      );

      const grammarModel = GrammarModel(
        id: 1,
        title: 'Present Simple',
        grammarKey: 'present_simple',
        level: 2,
        contents: [contentModel],
        tag: ['basic', 'tense'],
        related: [2, 3],
      );

      // act
      final entity = grammarModel.toEntity();

      // assert
      expect(entity.contents, isNotNull);
      expect(entity.contents!.length, 1);
      expect(entity.tag, isNotNull);
      expect(entity.tag!.length, 2);
      expect(entity.related, isNotNull);
      expect(entity.related!.length, 2);
    });
  });

  group('ContentModel', () {
    test('should convert from JSON correctly', () async {
      // arrange
      final jsonMap = {
        'sub_title': 'Usage',
        'content': [
          {
            'c': 'This is a grammar explanation.',
            'f': ['S + V(s/es) + O'],
            'e': [
              {'e': 'She goes to school everyday.'},
            ],
          },
        ],
      };

      // act
      final result = ContentModel.fromJson(jsonMap);

      // assert
      expect(result.subTitle, 'Usage');
      expect(result.content?.length, 1);
      expect(result.content?.first.content, 'This is a grammar explanation.');
      expect(result.content?.first.formulas?.first, 'S + V(s/es) + O');
      expect(
        result.content?.first.examples?.first.example,
        'She goes to school everyday.',
      );
    });

    test('should convert to entity correctly', () async {
      // arrange
      const contentModel = ContentModel(
        subTitle: 'Usage',
        content: [
          ContentElementModel(
            content: 'This is a grammar explanation.',
            formulas: ['S + V(s/es) + O'],
            examples: [
              ExampleModel(example: 'She goes to school everyday.'),
            ],
          ),
        ],
      );

      // act
      final entity = contentModel.toEntity();

      // assert
      expect(entity.subTitle, 'Usage');
      expect(entity.content?.length, 1);
      expect(entity.content?.first.content, 'This is a grammar explanation.');
      expect(entity.content?.first.formulas?.first, 'S + V(s/es) + O');
      expect(
        entity.content?.first.examples?.first.example,
        'She goes to school everyday.',
      );
    });
  });

  group('ContentElementModel', () {
    test('should convert from JSON correctly', () async {
      // arrange
      final jsonMap = {
        'c': 'This is a grammar explanation.',
        'f': ['S + V(s/es) + O'],
        'e': [
          {'e': 'She goes to school everyday.'},
        ],
      };

      // act
      final result = ContentElementModel.fromJson(jsonMap);

      // assert
      expect(result.content, 'This is a grammar explanation.');
      expect(result.formulas?.first, 'S + V(s/es) + O');
      expect(result.examples?.first.example, 'She goes to school everyday.');
    });

    test('should convert to entity correctly', () async {
      // arrange
      const contentElementModel = ContentElementModel(
        content: 'This is a grammar explanation.',
        formulas: ['S + V(s/es) + O'],
        examples: [
          ExampleModel(example: 'She goes to school everyday.'),
        ],
      );

      // act
      final entity = contentElementModel.toEntity();

      // assert
      expect(entity.content, 'This is a grammar explanation.');
      expect(entity.formulas?.first, 'S + V(s/es) + O');
      expect(entity.examples?.first.example, 'She goes to school everyday.');
    });
  });

  group('ExampleModel', () {
    test('should convert from JSON correctly', () async {
      // arrange
      final jsonMap = {'e': 'She goes to school everyday.'};

      // act
      final result = ExampleModel.fromJson(jsonMap);

      // assert
      expect(result.example, 'She goes to school everyday.');
    });

    test('should convert to entity correctly', () async {
      // arrange
      const exampleModel = ExampleModel(
        example: 'She goes to school everyday.',
      );

      // act
      final entity = exampleModel.toEntity();

      // assert
      expect(entity.example, 'She goes to school everyday.');
    });
  });
}
