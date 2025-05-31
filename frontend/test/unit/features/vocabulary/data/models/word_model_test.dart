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
        means: MeaningModel(data: [meaningData]),
        snym: SynonymModel(data: [synonymData]),
        conjugation: ConjugationModel(data: conjugationData),
      );

      // act
      final entity = wordModel.toEntity();

      // assert
      expect(entity.conjugation, isNotNull);
      expect(entity.means.length, 1);
      expect(entity.snym.length, 1);
      expect(entity.conjugation?.simplePresent?.p, 'go');
      expect(entity.means.first.kind, 'noun');
      expect(entity.snym.first.kind, 'synonym');
    });
  });

  group('MeaningModel', () {
    test('should convert from JSON correctly', () async {
      // arrange
      final jsonMap = {
        'RawMessage': [
          {
            'kind': 'noun',
            'means': [
              {
                'mean': 'a sample or instance',
                'examples': [1, 2, 3],
              },
            ],
          },
        ],
      };

      // act
      final result = MeaningModel.fromJson(jsonMap);

      // assert
      expect(result.data?.length, 1);
      expect(result.data?.first.kind, 'noun');
      expect(result.data?.first.means?.length, 1);
      expect(result.data?.first.means?.first.mean, 'a sample or instance');
    });

    test('should convert to entity list correctly', () async {
      // arrange
      const meaningModel = MeaningModel(
        data: [
          MeaningData(
            kind: 'noun',
            means: [
              MeanModel(mean: 'a sample or instance', examples: [1, 2, 3]),
            ],
          ),
        ],
      );

      // act
      final entities = meaningModel.toEntity();

      // assert
      expect(entities.length, 1);
      expect(entities.first.kind, 'noun');
      expect(entities.first.means?.length, 1);
      expect(entities.first.means?.first.mean, 'a sample or instance');
    });
  });

  group('SynonymModel', () {
    test('should convert from JSON correctly', () async {
      // arrange
      final jsonMap = {
        'RawMessage': [
          {
            'kind': 'synonym',
            'content': [
              {
                'syno': ['sample', 'instance'],
                'anto': ['original'],
              },
            ],
          },
        ],
      };

      // act
      final result = SynonymModel.fromJson(jsonMap);

      // assert
      expect(result.data?.length, 1);
      expect(result.data?.first.kind, 'synonym');
      expect(result.data?.first.content.length, 1);
      expect(result.data?.first.content.first.synonym, ['sample', 'instance']);
      expect(result.data?.first.content.first.antonym, ['original']);
    });

    test('should convert to entity list correctly', () async {
      // arrange
      const synonymModel = SynonymModel(
        data: [
          SynonymData(
            kind: 'synonym',
            content: [
              ContentModel(
                synonym: ['sample', 'instance'],
                antonym: ['original'],
              ),
            ],
          ),
        ],
      );

      // act
      final entities = synonymModel.toEntity();

      // assert
      expect(entities.length, 1);
      expect(entities.first.kind, 'synonym');
      expect(entities.first.content?.length, 1);
      expect(entities.first.content?.first.synonym, ['sample', 'instance']);
      expect(entities.first.content?.first.antonym, ['original']);
    });
  });

  group('ConjugationModel', () {
    test('should convert from JSON correctly', () async {
      // arrange
      final jsonMap = {
        'RawMessage': {
          'htd': {'p': 'go', 'w': 'goes'},
          'qkd': {'p': 'went', 'w': 'went'},
          'httd': {'p': 'going', 'w': 'going'},
          'htht': {'p': 'gone', 'w': 'gone'},
        },
      };

      // act
      final result = ConjugationModel.fromJson(jsonMap);

      // assert
      expect(result.data?.simplePresent?.p, 'go');
      expect(result.data?.simplePresent?.w, 'goes');
      expect(result.data?.simplePast?.p, 'went');
      expect(result.data?.simplePast?.w, 'went');
      expect(result.data?.presentContinuous?.p, 'going');
      expect(result.data?.presentContinuous?.w, 'going');
      expect(result.data?.presentParticiple?.p, 'gone');
      expect(result.data?.presentParticiple?.w, 'gone');
    });

    test('should convert to entity correctly', () async {
      // arrange
      const conjugationModel = ConjugationModel(
        data: ConjugationData(
          simplePresent: WordStateModel(p: 'go', w: 'goes'),
          simplePast: WordStateModel(p: 'went', w: 'went'),
          presentContinuous: WordStateModel(p: 'going', w: 'going'),
          presentParticiple: WordStateModel(p: 'gone', w: 'gone'),
        ),
      );

      // act
      final entity = conjugationModel.toEntity();

      // assert
      expect(entity.simplePresent?.p, 'go');
      expect(entity.simplePresent?.w, 'goes');
      expect(entity.simplePast?.p, 'went');
      expect(entity.simplePast?.w, 'went');
      expect(entity.presentContinuous?.p, 'going');
      expect(entity.presentContinuous?.w, 'going');
      expect(entity.presentParticiple?.p, 'gone');
      expect(entity.presentParticiple?.w, 'gone');
    });

    test('should handle null conjugation data', () async {
      // arrange
      const conjugationModel = ConjugationModel();

      // act
      final entity = conjugationModel.toEntity();

      // assert
      expect(entity.simplePresent, isNull);
      expect(entity.simplePast, isNull);
      expect(entity.presentContinuous, isNull);
      expect(entity.presentParticiple, isNull);
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
