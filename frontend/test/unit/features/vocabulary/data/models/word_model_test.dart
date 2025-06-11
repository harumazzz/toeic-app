import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/vocabulary/data/models/word_model.dart';
import 'package:learn/features/vocabulary/domain/entities/word.dart';

void main() {
  group('WordModel', () {
    const tWordModel = WordModel(
      id: 1,
      word: 'example',
      pronounce: 'ɪɡˈzæmpəl',
      level: 1,
      descriptLevel: 'A1',
      shortMean: 'short meaning',
      freq: 100,
    );

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

    test('should be a subclass of Word entity', () async {
      // assert
      expect(tWordModel.toEntity(), isA<Word>());
    });

    test('should convert from JSON correctly', () async {
      // arrange
      final Map<String, dynamic> jsonMap = {
        'id': 1,
        'word': 'example',
        'pronounce': 'ɪɡˈzæmpəl',
        'level': 1,
        'descript_level': 'A1',
        'short_mean': 'short meaning',
        'freq': 100,
        'means': null,
        'snym': null,
        'conjugation': null,
      };

      // act
      final result = WordModel.fromJson(jsonMap);

      // assert
      expect(result, tWordModel);
    });

    test('should convert to JSON correctly', () async {
      // arrange
      final expectedJson = {
        'id': 1,
        'word': 'example',
        'pronounce': 'ɪɡˈzæmpəl',
        'level': 1,
        'descript_level': 'A1',
        'short_mean': 'short meaning',
        'freq': 100,
        'means': null,
        'snym': null,
        'conjugation': null,
      };

      // act
      final result = tWordModel.toJson();

      // assert
      expect(result, expectedJson);
    });

    test('should convert to entity correctly', () async {
      // act
      final result = tWordModel.toEntity();

      // assert
      expect(result, tWord);
      expect(result.id, 1);
      expect(result.word, 'example');
      expect(result.pronounce, 'ɪɡˈzæmpəl');
      expect(result.level, 1);
      expect(result.descriptLevel, 'A1');
      expect(result.shortMean, 'short meaning');
      expect(result.freq, 100);
      expect(result.means, isEmpty);
      expect(result.snym, isEmpty);
      expect(result.conjugation, isNull);
    });

    test('should handle complex word model with all fields', () async {
      // arrange
      const conjugationData = ConjugationData(
        simplePresent: WordStateModel(p: 'go', w: 'goes'),
        simplePast: WordStateModel(p: 'went', w: 'went'),
        presentContinuous: WordStateModel(p: 'going', w: 'going'),
        presentParticiple: WordStateModel(p: 'gone', w: 'gone'),
      );

      const meaningData = MeaningData(
        kind: 'noun',
        means: [
          MeanModel(mean: 'a sample or instance', examples: [1, 2, 3]),
        ],
      );

      const synonymData = SynonymData(
        kind: 'synonym',
        content: [
          ContentModel(
            synonym: ['sample', 'instance'],
            antonym: ['original'],
          ),
        ],
      );

      const wordModel = WordModel(
        id: 1,
        word: 'example',
        pronounce: 'ɪɡˈzæmpəl',
        level: 1,
        descriptLevel: 'A1',
        shortMean: 'short meaning',
        freq: 100,
        means: [meaningData],
        snym: [synonymData],
        conjugation: conjugationData,
      );

      // act
      final entity = wordModel.toEntity();

      // assert
      expect(entity.conjugation, isNotNull);
      expect(entity.means!.length, 1);
      expect(entity.snym!.length, 1);
      expect(entity.conjugation?.simplePresent?.p, 'go');
      expect(entity.means!.first.kind, 'noun');
      expect(entity.snym!.first.kind, 'synonym');
    });
  });

  group('WordStateModel', () {
    test('should convert from JSON correctly', () async {
      // arrange
      final jsonMap = {'p': 'go', 'w': 'goes'};

      // act
      final result = WordStateModel.fromJson(jsonMap);

      // assert
      expect(result.p, 'go');
      expect(result.w, 'goes');
    });

    test('should convert to entity correctly', () async {
      // arrange
      const wordStateModel = WordStateModel(p: 'go', w: 'goes');

      // act
      final entity = wordStateModel.toEntity();

      // assert
      expect(entity.p, 'go');
      expect(entity.w, 'goes');
    });
  });
}
