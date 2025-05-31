import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/vocabulary/domain/entities/word.dart';

void main() {
  group('Word Entity', () {
    const tWord = Word(
      id: 1,
      word: 'example',
      pronounce: 'ɪɡˈzæmpəl',
      level: 1,
      descriptLevel: 'A1',
      shortMean: 'short meaning',
      freq: 100,
      means: [],
      snym: [],
    );

    test('should create Word entity with correct values', () {
      // assert
      expect(tWord.id, 1);
      expect(tWord.word, 'example');
      expect(tWord.pronounce, 'ɪɡˈzæmpəl');
      expect(tWord.level, 1);
      expect(tWord.descriptLevel, 'A1');
      expect(tWord.shortMean, 'short meaning');
      expect(tWord.freq, 100);
      expect(tWord.means, isEmpty);
      expect(tWord.snym, isEmpty);
      expect(tWord.conjugation, isNull);
    });

    test('should support equality comparison', () {
      // arrange
      const word1 = Word(
        id: 1,
        word: 'example',
        pronounce: 'ɪɡˈzæmpəl',
        level: 1,
        descriptLevel: 'A1',
        shortMean: 'short meaning',
        freq: 100,
        means: [],
        snym: [],
      );

      const word2 = Word(
        id: 1,
        word: 'example',
        pronounce: 'ɪɡˈzæmpəl',
        level: 1,
        descriptLevel: 'A1',
        shortMean: 'short meaning',
        freq: 100,
        means: [],
        snym: [],
      );

      // assert
      expect(word1, word2);
      expect(word1.hashCode, word2.hashCode);
    });

    test('should handle complex word with all fields', () {
      // arrange
      const conjugation = Conjugation(
        simplePresent: WordState(p: 'go', w: 'goes'),
        simplePast: WordState(p: 'went', w: 'went'),
        presentContinuous: WordState(p: 'going', w: 'going'),
        presentParticiple: WordState(p: 'gone', w: 'gone'),
      );

      const meaning = Meaning(
        kind: 'noun',
        means: [
          Mean(mean: 'a sample or instance', examples: [1, 2, 3]),
        ],
      );

      const synonym = Synonym(
        kind: 'synonym',
        content: [
          Content(
            synonym: ['sample', 'instance'],
            antonym: ['original'],
          ),
        ],
      );

      const word = Word(
        id: 1,
        word: 'example',
        pronounce: 'ɪɡˈzæmpəl',
        level: 1,
        descriptLevel: 'A1',
        shortMean: 'short meaning',
        freq: 100,
        means: [meaning],
        snym: [synonym],
        conjugation: conjugation,
      );

      // assert
      expect(word.conjugation, conjugation);
      expect(word.means.length, 1);
      expect(word.snym.length, 1);
      expect(word.means.first.kind, 'noun');
      expect(word.snym.first.kind, 'synonym');
    });
  });

  group('WordState Entity', () {
    test('should create WordState with correct values', () {
      // arrange
      const wordState = WordState(p: 'go', w: 'goes');

      // assert
      expect(wordState.p, 'go');
      expect(wordState.w, 'goes');
    });

    test('should handle null values', () {
      // arrange
      const wordState = WordState(p: null, w: null);

      // assert
      expect(wordState.p, isNull);
      expect(wordState.w, isNull);
    });
  });

  group('Conjugation Entity', () {
    test('should create Conjugation with all verb forms', () {
      // arrange
      const conjugation = Conjugation(
        simplePresent: WordState(p: 'go', w: 'goes'),
        simplePast: WordState(p: 'went', w: 'went'),
        presentContinuous: WordState(p: 'going', w: 'going'),
        presentParticiple: WordState(p: 'gone', w: 'gone'),
      );

      // assert
      expect(conjugation.simplePresent?.p, 'go');
      expect(conjugation.simplePresent?.w, 'goes');
      expect(conjugation.simplePast?.p, 'went');
      expect(conjugation.simplePast?.w, 'went');
      expect(conjugation.presentContinuous?.p, 'going');
      expect(conjugation.presentContinuous?.w, 'going');
      expect(conjugation.presentParticiple?.p, 'gone');
      expect(conjugation.presentParticiple?.w, 'gone');
    });

    test('should handle partial conjugation data', () {
      // arrange
      const conjugation = Conjugation(
        simplePresent: WordState(p: 'go', w: 'goes'),
      );

      // assert
      expect(conjugation.simplePresent, isNotNull);
      expect(conjugation.simplePast, isNull);
      expect(conjugation.presentContinuous, isNull);
      expect(conjugation.presentParticiple, isNull);
    });
  });

  group('Synonym Entity', () {
    test('should create Synonym with content', () {
      // arrange
      const synonym = Synonym(
        kind: 'synonym',
        content: [
          Content(
            synonym: ['sample', 'instance'],
            antonym: ['original'],
          ),
        ],
      );

      // assert
      expect(synonym.kind, 'synonym');
      expect(synonym.content?.length, 1);
      expect(synonym.content?.first.synonym, ['sample', 'instance']);
      expect(synonym.content?.first.antonym, ['original']);
    });

    test('should handle empty content', () {
      // arrange
      const synonym = Synonym(kind: 'synonym', content: null);

      // assert
      expect(synonym.kind, 'synonym');
      expect(synonym.content, isNull);
    });
  });

  group('Content Entity', () {
    test('should create Content with synonyms and antonyms', () {
      // arrange
      const content = Content(
        synonym: ['sample', 'instance'],
        antonym: ['original'],
      );

      // assert
      expect(content.synonym, ['sample', 'instance']);
      expect(content.antonym, ['original']);
    });

    test('should handle null synonym and antonym lists', () {
      // arrange
      const content = Content(synonym: null, antonym: null);

      // assert
      expect(content.synonym, isNull);
      expect(content.antonym, isNull);
    });
  });

  group('Meaning Entity', () {
    test('should create Meaning with means', () {
      // arrange
      const meaning = Meaning(
        kind: 'noun',
        means: [
          Mean(mean: 'a sample or instance', examples: [1, 2, 3]),
          Mean(mean: 'another meaning', examples: [4, 5]),
        ],
      );

      // assert
      expect(meaning.kind, 'noun');
      expect(meaning.means?.length, 2);
      expect(meaning.means?.first.mean, 'a sample or instance');
      expect(meaning.means?.first.examples, [1, 2, 3]);
    });

    test('should handle empty means', () {
      // arrange
      const meaning = Meaning(kind: 'noun', means: null);

      // assert
      expect(meaning.kind, 'noun');
      expect(meaning.means, isNull);
    });
  });

  group('Mean Entity', () {
    test('should create Mean with examples', () {
      // arrange
      const mean = Mean(
        mean: 'a sample or instance',
        examples: [1, 2, 3],
      );

      // assert
      expect(mean.mean, 'a sample or instance');
      expect(mean.examples, [1, 2, 3]);
    });

    test('should handle null mean and examples', () {
      // arrange
      const mean = Mean(mean: null, examples: null);

      // assert
      expect(mean.mean, isNull);
      expect(mean.examples, isNull);
    });
  });
}
