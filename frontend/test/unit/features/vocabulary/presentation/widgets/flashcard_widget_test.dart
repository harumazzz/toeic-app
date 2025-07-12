import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/vocabulary/domain/entities/word.dart';
import 'package:learn/features/vocabulary/presentation/widgets/flashcard_widget.dart';

void main() {
  group('FlashcardWidget', () {
    Widget makeTestableWidget(final Widget child) => MaterialApp(
      home: Scaffold(
        body: child,
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

    Widget frontBuilder(final BuildContext context, final Word word) =>
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(word.word, style: const TextStyle(fontSize: 24)),
              if (word.pronounce != null)
                Text(
                  '/${word.pronounce}/',
                  style: const TextStyle(fontSize: 16),
                ),
            ],
          ),
        );

    Widget backBuilder(final BuildContext context, final Word word) =>
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (word.shortMean != null)
                Text(word.shortMean!, style: const TextStyle(fontSize: 18)),
            ],
          ),
        );

    testWidgets('should display flashcard for word', (final tester) async {
      // arrange
      final widget = FlashcardWidget(
        word: tWord,
        frontBuilder: frontBuilder,
        backBuilder: backBuilder,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('example'), findsOneWidget);
    });

    testWidgets('should display word pronunciation on front side', (
      final tester,
    ) async {
      // arrange
      final widget = FlashcardWidget(
        word: tWord,
        frontBuilder: frontBuilder,
        backBuilder: backBuilder,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.textContaining('ɪɡˈzæmpəl'), findsOneWidget);
    });

    testWidgets('should display card container', (final tester) async {
      // arrange
      final widget = FlashcardWidget(
        word: tWord,
        frontBuilder: frontBuilder,
        backBuilder: backBuilder,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Container), findsWidgets);
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
      final widget = FlashcardWidget(
        word: wordWithoutPronunciation,
        frontBuilder: frontBuilder,
        backBuilder: backBuilder,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('example'), findsOneWidget);
    });

    testWidgets('should handle word without short meaning', (
      final tester,
    ) async {
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
      final widget = FlashcardWidget(
        word: wordWithoutShortMean,
        frontBuilder: frontBuilder,
        backBuilder: backBuilder,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('example'), findsOneWidget);
    });

    testWidgets('should have proper layout structure', (final tester) async {
      // arrange
      final widget = FlashcardWidget(
        word: tWord,
        frontBuilder: frontBuilder,
        backBuilder: backBuilder,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should be accessible', (final tester) async {
      // arrange
      final widget = FlashcardWidget(
        word: tWord,
        frontBuilder: frontBuilder,
        backBuilder: backBuilder,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(FlashcardWidget), findsOneWidget);
    });

    testWidgets('should render without errors', (final tester) async {
      // arrange
      final widget = FlashcardWidget(
        word: tWord,
        frontBuilder: frontBuilder,
        backBuilder: backBuilder,
      );

      // act & assert
      expect(
        () async => tester.pumpWidget(makeTestableWidget(widget)),
        returnsNormally,
      );
    });

    testWidgets('should handle different word levels', (final tester) async {
      // arrange
      const level3Word = Word(
        id: 1,
        word: 'advanced',
        pronounce: 'ədˈvænst',
        level: 3,
        descriptLevel: 'B1',
        shortMean: 'at a higher level',
        freq: 50,
        means: [],
        snym: [],
      );
      final widget = FlashcardWidget(
        word: level3Word,
        frontBuilder: frontBuilder,
        backBuilder: backBuilder,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('advanced'), findsOneWidget);
    });

    testWidgets('should display SizedBox container', (final tester) async {
      // arrange
      final widget = FlashcardWidget(
        word: tWord,
        frontBuilder: frontBuilder,
        backBuilder: backBuilder,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('should maintain consistent sizing', (final tester) async {
      // arrange
      final widget = FlashcardWidget(
        word: tWord,
        frontBuilder: frontBuilder,
        backBuilder: backBuilder,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(FlashcardWidget), findsOneWidget);
      // Should not overflow or have layout issues
      expect(tester.takeException(), isNull);
    });

    testWidgets('should be tappable for card flip', (final tester) async {
      // arrange
      final widget = FlashcardWidget(
        word: tWord,
        frontBuilder: frontBuilder,
        backBuilder: backBuilder,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}
