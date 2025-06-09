import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/grammars/domain/entities/grammar.dart';

void main() {
  group('Grammar Entity Tests', () {
    test('should create a valid Grammar instance', () {
      const grammar = Grammar(
        id: 1,
        grammarKey: 'present_simple',
        level: 1,
        title: 'Present Simple',
        contents: [
          Content(
            subTitle: 'Basic Usage',
            content: [
              ContentElement(
                content: 'The present simple is used for...',
                formulas: ['Subject + V1'],
                examples: [
                  Example(example: 'I play tennis every Sunday.'),
                  Example(example: 'She works in a bank.'),
                ],
              ),
            ],
          ),
        ],
        related: [2, 3],
        tag: ['tense', 'basic'],
      );

      expect(grammar.id, 1);
      expect(grammar.grammarKey, 'present_simple');
      expect(grammar.level, 1);
      expect(grammar.title, 'Present Simple');
      expect(grammar.contents?.length, 1);
      expect(grammar.related, [2, 3]);
      expect(grammar.tag, ['tense', 'basic']);
    });

    test('should create a valid Content instance', () {
      const content = Content(
        subTitle: 'Basic Usage',
        content: [
          ContentElement(
            content: 'The present simple is used for...',
            formulas: ['Subject + V1'],
            examples: [
              Example(example: 'I play tennis every Sunday.'),
            ],
          ),
        ],
      );

      expect(content.subTitle, 'Basic Usage');
      expect(content.content?.length, 1);
      expect(content.content?[0].content, 'The present simple is used for...');
      expect(content.content?[0].formulas, ['Subject + V1']);
      expect(content.content?[0].examples?.length, 1);
      expect(
        content.content?[0].examples?[0].example,
        'I play tennis every Sunday.',
      );
    });

    test('should create a valid ContentElement instance', () {
      const element = ContentElement(
        content: 'The present simple is used for...',
        formulas: ['Subject + V1'],
        examples: [
          Example(example: 'I play tennis every Sunday.'),
          Example(example: 'She works in a bank.'),
        ],
      );

      expect(element.content, 'The present simple is used for...');
      expect(element.formulas, ['Subject + V1']);
      expect(element.examples?.length, 2);
      expect(element.examples?[0].example, 'I play tennis every Sunday.');
      expect(element.examples?[1].example, 'She works in a bank.');
    });

    test('should create a valid Example instance', () {
      const example = Example(example: 'I play tennis every Sunday.');

      expect(example.example, 'I play tennis every Sunday.');
    });

    test('should create a Grammar instance with null optional fields', () {
      const grammar = Grammar(
        id: 1,
        grammarKey: 'present_simple',
        level: 1,
        title: 'Present Simple',
      );

      expect(grammar.id, 1);
      expect(grammar.grammarKey, 'present_simple');
      expect(grammar.level, 1);
      expect(grammar.title, 'Present Simple');
      expect(grammar.contents, null);
      expect(grammar.related, null);
      expect(grammar.tag, null);
    });
  });
}
