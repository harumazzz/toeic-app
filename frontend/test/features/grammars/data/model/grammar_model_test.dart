import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/grammars/data/models/grammar_model.dart';

void main() {
  group('Grammar Model Tests', () {
    test('should create a valid GrammarModel instance', () {
      const model = GrammarModel(
        id: 1,
        grammarKey: 'present_simple',
        level: 1,
        title: 'Present Simple',
        contents: GrammarContentModel(
          contents: [
            ContentModel(
              subTitle: 'Basic Usage',
              content: [
                ContentElementModel(
                  content: 'The present simple is used for...',
                  formulas: ['Subject + V1'],
                  examples: [
                    ExampleModel(example: 'I play tennis every Sunday.'),
                    ExampleModel(example: 'She works in a bank.'),
                  ],
                ),
              ],
            ),
          ],
        ),
        related: [2, 3],
        tag: ['tense', 'basic'],
      );

      expect(model.id, 1);
      expect(model.grammarKey, 'present_simple');
      expect(model.level, 1);
      expect(model.title, 'Present Simple');
      expect(model.contents?.contents?.length, 1);
      expect(model.related, [2, 3]);
      expect(model.tag, ['tense', 'basic']);
    });

    test('should create a valid GrammarContentModel instance', () {
      const model = GrammarContentModel(
        contents: [
          ContentModel(
            subTitle: 'Basic Usage',
            content: [
              ContentElementModel(
                content: 'The present simple is used for...',
                formulas: ['Subject + V1'],
                examples: [
                  ExampleModel(example: 'I play tennis every Sunday.'),
                ],
              ),
            ],
          ),
        ],
      );

      expect(model.contents?.length, 1);
      expect(model.contents?[0].subTitle, 'Basic Usage');
      expect(model.contents?[0].content?.length, 1);
    });

    test('should create a valid ContentModel instance', () {
      const model = ContentModel(
        subTitle: 'Basic Usage',
        content: [
          ContentElementModel(
            content: 'The present simple is used for...',
            formulas: ['Subject + V1'],
            examples: [
              ExampleModel(example: 'I play tennis every Sunday.'),
            ],
          ),
        ],
      );

      expect(model.subTitle, 'Basic Usage');
      expect(model.content?.length, 1);
      expect(model.content?[0].content, 'The present simple is used for...');
      expect(model.content?[0].formulas, ['Subject + V1']);
      expect(model.content?[0].examples?.length, 1);
      expect(
        model.content?[0].examples?[0].example,
        'I play tennis every Sunday.',
      );
    });

    test('should create a valid ContentElementModel instance', () {
      const model = ContentElementModel(
        content: 'The present simple is used for...',
        formulas: ['Subject + V1'],
        examples: [
          ExampleModel(example: 'I play tennis every Sunday.'),
          ExampleModel(example: 'She works in a bank.'),
        ],
      );

      expect(model.content, 'The present simple is used for...');
      expect(model.formulas, ['Subject + V1']);
      expect(model.examples?.length, 2);
      expect(model.examples?[0].example, 'I play tennis every Sunday.');
      expect(model.examples?[1].example, 'She works in a bank.');
    });

    test('should create a valid ExampleModel instance', () {
      const model = ExampleModel(example: 'I play tennis every Sunday.');

      expect(model.example, 'I play tennis every Sunday.');
    });

    test('should convert GrammarModel to entity', () {
      const model = GrammarModel(
        id: 1,
        grammarKey: 'present_simple',
        level: 1,
        title: 'Present Simple',
        contents: GrammarContentModel(
          contents: [
            ContentModel(
              subTitle: 'Basic Usage',
              content: [
                ContentElementModel(
                  content: 'The present simple is used for...',
                  formulas: ['Subject + V1'],
                  examples: [
                    ExampleModel(example: 'I play tennis every Sunday.'),
                  ],
                ),
              ],
            ),
          ],
        ),
        related: [2, 3],
        tag: ['tense', 'basic'],
      );

      final entity = model.toEntity();

      expect(entity.id, model.id);
      expect(entity.grammarKey, model.grammarKey);
      expect(entity.level, model.level);
      expect(entity.title, model.title);
      expect(entity.related, model.related);
      expect(entity.tag, model.tag);
      expect(entity.contents?.length, model.contents?.contents?.length);
      expect(
        entity.contents?[0].subTitle,
        model.contents?.contents?[0].subTitle,
      );
      expect(
        entity.contents?[0].content?.length,
        model.contents?.contents?[0].content?.length,
      );
    });

    test('should create a GrammarModel instance with null optional fields', () {
      const model = GrammarModel(
        id: 1,
        grammarKey: 'present_simple',
        level: 1,
        title: 'Present Simple',
      );

      expect(model.id, 1);
      expect(model.grammarKey, 'present_simple');
      expect(model.level, 1);
      expect(model.title, 'Present Simple');
      expect(model.contents, null);
      expect(model.related, null);
      expect(model.tag, null);
    });
  });
}
