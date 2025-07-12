import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/grammars/domain/entities/grammar.dart';
import 'package:learn/features/grammars/presentation/widgets/grammar_list_item.dart';
import 'package:learn/i18n/strings.g.dart';

void main() {
  group('GrammarListItem Widget', () {
    Widget makeTestableWidget(final Widget child) => MaterialApp(
      home: TranslationProvider(
        child: Scaffold(
          body: SingleChildScrollView(
            child: child,
          ),
        ),
      ),
    );

    const tGrammar = Grammar(
      id: 1,
      grammarKey: 'present-simple',
      title: 'Present Simple Tense',
      level: 1,
      tag: ['basic', 'tense', 'beginner'],
    );

    const tGrammarWithoutTags = Grammar(
      id: 2,
      grammarKey: 'past-simple',
      title: 'Past Simple Tense',
      level: 2,
    );

    testWidgets('should display grammar information correctly', (
      final tester,
    ) async {
      // arrange
      bool onTapCalled = false;
      final widget = GrammarListItem(
        grammar: tGrammar,
        onTap: () => onTapCalled = true,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('Present Simple Tense'), findsOneWidget);
      expect(find.textContaining('1'), findsOneWidget); // Level text
      expect(find.text('basic'), findsOneWidget);
      expect(find.text('tense'), findsOneWidget);
      expect(find.text('beginner'), findsOneWidget);
    });

    testWidgets('should display grammar without tags correctly', (
      final tester,
    ) async {
      // arrange
      bool onTapCalled = false;
      final widget = GrammarListItem(
        grammar: tGrammarWithoutTags,
        onTap: () => onTapCalled = true,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('Past Simple Tense'), findsOneWidget);
      expect(find.textContaining('2'), findsOneWidget); // Level text
      // No tags should be displayed
      expect(find.text('basic'), findsNothing);
      expect(find.text('tense'), findsNothing);
    });

    testWidgets('should handle empty tags list correctly', (
      final tester,
    ) async {
      // arrange
      const grammarWithEmptyTags = Grammar(
        id: 3,
        grammarKey: 'future-simple',
        title: 'Future Simple Tense',
        level: 1,
        tag: [],
      );

      bool onTapCalled = false;
      final widget = GrammarListItem(
        grammar: grammarWithEmptyTags,
        onTap: () => onTapCalled = true,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('Future Simple Tense'), findsOneWidget);
      expect(find.textContaining('1'), findsOneWidget); // Level text
      // No tags should be displayed for empty list
      expect(find.text('basic'), findsNothing);
      expect(find.text('tense'), findsNothing);
    });

    testWidgets('should call onTap when tapped', (final tester) async {
      // arrange
      bool onTapCalled = false;
      final inkWellKey = const Key('grammarListItemInkWell');
      final widget = GrammarListItem(
        grammar: tGrammar,
        onTap: () => onTapCalled = true,
        inkWellKey: inkWellKey,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));
      await tester.tap(find.byKey(inkWellKey));
      await tester.pump();

      // assert
      expect(onTapCalled, isTrue);
    });

    testWidgets('should have correct card styling', (final tester) async {
      // arrange
      bool onTapCalled = false;
      final inkWellKey = const Key('grammarListItemInkWell');
      final widget = GrammarListItem(
        grammar: tGrammar,
        onTap: () => onTapCalled = true,
        inkWellKey: inkWellKey,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Card), findsOneWidget);
      expect(find.byKey(inkWellKey), findsOneWidget);

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, equals(2));
      expect(card.shape, isA<RoundedRectangleBorder>());

      final inkWell = tester.widget<InkWell>(find.byKey(inkWellKey));
      expect(inkWell.borderRadius, isA<BorderRadius>());
    });

    testWidgets('should display level text with correct format', (
      final tester,
    ) async {
      // arrange
      bool onTapCalled = false;
      final widget = GrammarListItem(
        grammar: tGrammar,
        onTap: () => onTapCalled = true,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Find the level text widget
      final levelTextFinder = find.textContaining('1');
      expect(levelTextFinder, findsOneWidget);

      final levelText = tester.widget<Text>(levelTextFinder);
      expect(levelText.style?.fontWeight, equals(FontWeight.w500));
    });

    testWidgets('should display title with correct styling', (
      final tester,
    ) async {
      // arrange
      bool onTapCalled = false;
      final widget = GrammarListItem(
        grammar: tGrammar,
        onTap: () => onTapCalled = true,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      final titleTextFinder = find.text('Present Simple Tense');
      expect(titleTextFinder, findsOneWidget);

      final titleText = tester.widget<Text>(titleTextFinder);
      expect(titleText.style?.fontWeight, equals(FontWeight.w600));
      expect(titleText.maxLines, equals(2));
      expect(titleText.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('should handle long titles correctly', (final tester) async {
      // arrange
      const grammarWithLongTitle = Grammar(
        id: 4,
        grammarKey: 'conditional-sentences',
        title:
            'This is a very long grammar title that should be truncated when it exceeds the maximum number of lines allowed',
        level: 3,
      );

      bool onTapCalled = false;
      final widget = GrammarListItem(
        grammar: grammarWithLongTitle,
        onTap: () => onTapCalled = true,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      final titleTextFinder = find.textContaining(
        'This is a very long grammar title',
      );
      expect(titleTextFinder, findsOneWidget);

      final titleText = tester.widget<Text>(titleTextFinder);
      expect(titleText.maxLines, equals(2));
      expect(titleText.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('should display multiple tags correctly', (final tester) async {
      // arrange
      const grammarWithManyTags = Grammar(
        id: 5,
        grammarKey: 'complex-grammar',
        title: 'Complex Grammar Rule',
        level: 4,
        tag: ['advanced', 'complex', 'conditional', 'subjunctive', 'formal'],
      );

      bool onTapCalled = false;
      final widget = GrammarListItem(
        grammar: grammarWithManyTags,
        onTap: () => onTapCalled = true,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('advanced'), findsOneWidget);
      expect(find.text('complex'), findsOneWidget);
      expect(find.text('conditional'), findsOneWidget);
      expect(find.text('subjunctive'), findsOneWidget);
      expect(find.text('formal'), findsOneWidget);
    });

    testWidgets('should have proper layout structure', (final tester) async {
      // arrange
      bool onTapCalled = false;
      final inkWellKey = const Key('grammarListItemInkWell');
      final widget = GrammarListItem(
        grammar: tGrammar,
        onTap: () => onTapCalled = true,
        inkWellKey: inkWellKey,
      );

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Card), findsOneWidget);
      expect(find.byKey(inkWellKey), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
