import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/vocabulary/domain/entities/word.dart';
import 'package:learn/features/vocabulary/presentation/widgets/word_card.dart';
import 'package:learn/i18n/strings.g.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  group('WordCard Widget', () {
    Widget makeTestableWidget(final Widget child) => MaterialApp(
      home: TranslationProvider(
        child: Scaffold(
          body: SingleChildScrollView(
            child: child,
          ),
        ),
      ),
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

    testWidgets('should display word information correctly', (
      final tester,
    ) async {
      // arrange
      const widget = WordCard(word: tWord);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('example'), findsOneWidget);
      expect(find.text('ɪɡˈzæmpəl'), findsOneWidget);
      expect(find.text('short meaning'), findsOneWidget);
      expect(find.text('A1'), findsOneWidget);
    });

    testWidgets('should display level icon correctly', (final tester) async {
      // arrange
      const widget = WordCard(word: tWord);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byIcon(Symbols.star), findsOneWidget);
    });

    testWidgets('should display action buttons', (final tester) async {
      // arrange
      const widget = WordCard(word: tWord);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byIcon(Symbols.volume_up), findsOneWidget);
      expect(find.byIcon(Symbols.arrow_forward), findsOneWidget);
    });

    testWidgets('should handle word without pronunciation', (
      final tester,
    ) async {
      // arrange
      const wordWithoutPronunciation = Word(
        id: 1,
        word: 'example',
        pronounce: null,
        level: 1,
        descriptLevel: 'A1',
        shortMean: 'short meaning',
        freq: 100,
        means: [],
        snym: [],
      );
      const widget = WordCard(word: wordWithoutPronunciation);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('example'), findsOneWidget);
      expect(find.text('/ɪɡˈzæmpəl/'), findsNothing);
    });

    testWidgets('should handle word without shortMean', (final tester) async {
      // arrange
      const wordWithoutShortMean = Word(
        id: 1,
        word: 'example',
        pronounce: 'ɪɡˈzæmpəl',
        level: 1,
        descriptLevel: 'A1',
        shortMean: null,
        freq: 100,
        means: [],
        snym: [],
      );
      const widget = WordCard(word: wordWithoutShortMean);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('example'), findsOneWidget);
      expect(find.text('short meaning'), findsNothing);
    });

    testWidgets('should display correct level icon for different levels', (
      final tester,
    ) async {
      // arrange
      const level2Word = Word(
        id: 1,
        word: 'example',
        pronounce: 'ɪɡˈzæmpəl',
        level: 2,
        descriptLevel: 'A2',
        shortMean: 'short meaning',
        freq: 100,
        means: [],
        snym: [],
      );
      const widget = WordCard(word: level2Word);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byIcon(Symbols.auto_awesome), findsOneWidget);
    });

    testWidgets('should display level 3 icon correctly', (final tester) async {
      // arrange
      const level3Word = Word(
        id: 1,
        word: 'example',
        pronounce: 'ɪɡˈzæmpəl',
        level: 3,
        descriptLevel: 'B1',
        shortMean: 'short meaning',
        freq: 100,
        means: [],
        snym: [],
      );
      const widget = WordCard(word: level3Word);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byIcon(Symbols.diamond), findsOneWidget);
    });

    testWidgets('should display level 4 icon correctly', (final tester) async {
      // arrange
      const level4Word = Word(
        id: 1,
        word: 'example',
        pronounce: 'ɪɡˈzæmpəl',
        level: 4,
        descriptLevel: 'B2',
        shortMean: 'short meaning',
        freq: 100,
        means: [],
        snym: [],
      );
      const widget = WordCard(word: level4Word);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byIcon(Symbols.emoji_events), findsOneWidget);
    });

    testWidgets('should display level 5 icon correctly', (final tester) async {
      // arrange
      const level5Word = Word(
        id: 1,
        word: 'example',
        pronounce: 'ɪɡˈzæmpəl',
        level: 5,
        descriptLevel: 'C1',
        shortMean: 'short meaning',
        freq: 100,
        means: [],
        snym: [],
      );
      const widget = WordCard(word: level5Word);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byIcon(Symbols.workspace_premium), findsOneWidget);
    });

    testWidgets('should display default icon for unknown levels', (
      final tester,
    ) async {
      // arrange
      const unknownLevelWord = Word(
        id: 1,
        word: 'example',
        pronounce: 'ɪɡˈzæmpəl',
        level: 10,
        descriptLevel: 'Unknown',
        shortMean: 'short meaning',
        freq: 100,
        means: [],
        snym: [],
      );
      const widget = WordCard(word: unknownLevelWord);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byIcon(Symbols.school), findsOneWidget);
    });

    testWidgets('should be tappable', (final tester) async {
      // arrange
      const widget = WordCard(word: tWord);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('should show audio button', (final tester) async {
      // arrange
      const widget = WordCard(word: tWord);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byIcon(Symbols.volume_up), findsOneWidget);
    });

    testWidgets('should show view details button', (final tester) async {
      // arrange
      const widget = WordCard(word: tWord);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byIcon(Symbols.arrow_forward), findsOneWidget);
    });

    testWidgets('should handle empty descriptLevel', (final tester) async {
      // arrange
      const wordWithoutDescriptLevel = Word(
        id: 1,
        word: 'example',
        pronounce: 'ɪɡˈzæmpəl',
        level: 1,
        descriptLevel: null,
        shortMean: 'short meaning',
        freq: 100,
        means: [],
        snym: [],
      );
      const widget = WordCard(word: wordWithoutDescriptLevel);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('example'), findsOneWidget);
      expect(find.text('Level 1'), findsOneWidget);
    });

    testWidgets('should display card container', (final tester) async {
      // arrange
      const widget = WordCard(word: tWord);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should have proper layout structure', (final tester) async {
      // arrange
      const widget = WordCard(word: tWord);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Padding), findsWidgets);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsWidgets);
    });
  });
}
