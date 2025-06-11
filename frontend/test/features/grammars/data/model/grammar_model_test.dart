import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/grammars/data/models/grammar_model.dart';

void main() {
  group('Grammar Model Tests', () {
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
