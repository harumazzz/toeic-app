import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/grammars/domain/entities/grammar.dart'
    as grammar;
import 'package:learn/features/grammars/presentation/widgets/grammar_content.dart';
import 'package:material_symbols_icons/symbols.dart';

void main() {
  group('GrammarContent Widget', () {
    Widget makeTestableWidget(final Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: child,
        ),
      ),
    );

    testWidgets('should display content with subtitle correctly', (
      final tester,
    ) async {
      // arrange
      const contents = [
        grammar.Content(
          subTitle: 'Basic Rules',
          content: [
            grammar.ContentElement(
              content: '<p>This is the content</p>',
            ),
          ],
        ),
      ];

      const widget = GrammarContent(contents: contents);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('Basic Rules'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should display content without subtitle as simple padding', (
      final tester,
    ) async {
      // arrange
      const contents = [
        grammar.Content(
          content: [
            grammar.ContentElement(
              content: '<p>This is the content</p>',
            ),
          ],
        ),
      ];

      const widget = GrammarContent(contents: contents);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Card), findsNothing);
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('should display formula card with correct styling', (
      final tester,
    ) async {
      // arrange
      const contents = [
        grammar.Content(
          content: [
            grammar.ContentElement(
              formulas: ['Subject + Verb + Object'],
            ),
          ],
        ),
      ];

      const widget = GrammarContent(contents: contents);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('Formula'), findsOneWidget);
      expect(find.byIcon(Symbols.rule), findsOneWidget);
      expect(find.textContaining('Subject + Verb + Object'), findsWidgets);
    });

    testWidgets('should display example card with correct styling', (
      final tester,
    ) async {
      // arrange
      const contents = [
        grammar.Content(
          content: [
            grammar.ContentElement(
              examples: [
                grammar.Example(example: 'I eat an apple.'),
                grammar.Example(example: 'She reads a book.'),
              ],
            ),
          ],
        ),
      ];

      const widget = GrammarContent(contents: contents);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('Examples'), findsOneWidget);
      expect(find.byIcon(Symbols.lightbulb_outline), findsOneWidget);
      expect(find.textContaining('I eat an apple.'), findsOneWidget);
      expect(find.textContaining('She reads a book.'), findsOneWidget);
    });

    testWidgets('should display content, formula, and examples together', (
      final tester,
    ) async {
      // arrange
      const contents = [
        grammar.Content(
          subTitle: 'Present Simple',
          content: [
            grammar.ContentElement(
              content: '<p>The present simple tense is used for facts.</p>',
              formulas: ['Subject + Verb (base form)'],
              examples: [
                grammar.Example(example: 'I work every day.'),
              ],
            ),
          ],
        ),
      ];

      const widget = GrammarContent(contents: contents);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('Present Simple'), findsOneWidget);
      expect(find.text('Formula'), findsOneWidget);
      expect(find.text('Examples'), findsOneWidget);
      expect(find.textContaining('Subject + Verb'), findsOneWidget);
      expect(find.textContaining('I work every day'), findsOneWidget);
    });

    testWidgets('should handle multiple contents correctly', (
      final tester,
    ) async {
      // arrange
      const contents = [
        grammar.Content(
          subTitle: 'Positive Form',
          content: [
            grammar.ContentElement(
              content: '<p>Use base form of verb</p>',
            ),
          ],
        ),
        grammar.Content(
          subTitle: 'Negative Form',
          content: [
            grammar.ContentElement(
              content: '<p>Use do not + base form</p>',
            ),
          ],
        ),
      ];

      const widget = GrammarContent(contents: contents);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('Positive Form'), findsOneWidget);
      expect(find.text('Negative Form'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('should handle empty content gracefully', (
      final tester,
    ) async {
      // arrange
      const contents = <grammar.Content>[];
      const widget = GrammarContent(contents: contents);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(ListView), findsOneWidget);
      // Should not crash and display nothing
    });

    testWidgets('should handle content with empty subtitle', (
      final tester,
    ) async {
      // arrange
      const contents = [
        grammar.Content(
          subTitle: '',
          content: [
            grammar.ContentElement(
              content: '<p>Content without subtitle</p>',
            ),
          ],
        ),
      ];

      const widget = GrammarContent(contents: contents);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Should be displayed as simple padding since subtitle is empty
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('should handle content with null subtitle', (
      final tester,
    ) async {
      // arrange
      const contents = [
        grammar.Content(
          content: [
            grammar.ContentElement(
              content: '<p>Content with null subtitle</p>',
            ),
          ],
        ),
      ];

      const widget = GrammarContent(contents: contents);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Should be displayed as simple padding since subtitle is null
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('should handle multiple formulas correctly', (
      final tester,
    ) async {
      // arrange
      const contents = [
        grammar.Content(
          content: [
            grammar.ContentElement(
              formulas: [
                'Subject + Verb + Object',
                'Subject + do not + Verb + Object',
                'Do + Subject + Verb + Object?',
              ],
            ),
          ],
        ),
      ];

      const widget = GrammarContent(contents: contents);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('Formula'), findsOneWidget);
      expect(find.textContaining('Subject + Verb + Object'), findsWidgets);
      expect(find.textContaining('do not'), findsOneWidget);
      expect(find.textContaining('Do + Subject'), findsWidgets);
    });

    testWidgets('should handle empty examples gracefully', (
      final tester,
    ) async {
      // arrange
      const contents = [
        grammar.Content(
          content: [
            grammar.ContentElement(
              examples: [
                grammar.Example(),
                grammar.Example(example: ''),
              ],
            ),
          ],
        ),
      ];

      const widget = GrammarContent(contents: contents);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.text('Examples'), findsOneWidget);
      // Should handle null and empty examples without crashing
    });

    testWidgets('should have correct layout structure', (
      final tester,
    ) async {
      // arrange
      const contents = [
        grammar.Content(
          subTitle: 'Test Content',
          content: [
            grammar.ContentElement(
              content: '<p>Test</p>',
              formulas: ['Test formula'],
              examples: [grammar.Example(example: 'Test example')],
            ),
          ],
        ),
      ];

      const widget = GrammarContent(contents: contents);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should display subtitle with correct styling', (
      final tester,
    ) async {
      // arrange
      const contents = [
        grammar.Content(
          subTitle: 'Grammar Rule Title',
          content: [
            grammar.ContentElement(
              content: '<p>Content</p>',
            ),
          ],
        ),
      ];

      const widget = GrammarContent(contents: contents);

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      final titleFinder = find.text('Grammar Rule Title');
      expect(titleFinder, findsOneWidget);

      final titleText = tester.widget<Text>(titleFinder);
      expect(titleText.style?.fontWeight, equals(FontWeight.w600));
      expect(titleText.maxLines, equals(2));
      expect(titleText.overflow, equals(TextOverflow.ellipsis));
    });
  });
}
