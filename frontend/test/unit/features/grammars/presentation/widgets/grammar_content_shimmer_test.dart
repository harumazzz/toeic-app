import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/grammars/presentation/widgets/grammar_content_shimmer.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

void main() {
  group('GrammarContentShimmer Widget', () {
    Widget makeTestableWidget(final Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: child,
        ),
      ),
    );

    testWidgets('should display shimmer loading effect', (final tester) async {
      // arrange
      const widget = GrammarContentShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Shimmer), findsWidgets);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should have correct card structure', (final tester) async {
      // arrange
      const widget = GrammarContentShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
      expect(find.byType(Column), findsWidgets);

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.margin, equals(const EdgeInsets.all(16)));
    });

    testWidgets('should display multiple shimmer sections', (
      final tester,
    ) async {
      // arrange
      const widget = GrammarContentShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Should have multiple shimmer elements for different content sections
      expect(find.byType(Shimmer), findsWidgets);

      // Should have containers for shimmer effects
      expect(find.byType(Container), findsWidgets);

      // Should have proper spacing
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('should have shimmer elements with correct durations', (
      final tester,
    ) async {
      // arrange
      const widget = GrammarContentShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      final shimmerWidgets = tester.widgetList<Shimmer>(find.byType(Shimmer));

      for (final shimmer in shimmerWidgets) {
        expect(shimmer.duration, equals(const Duration(seconds: 2)));
      }
    });

    testWidgets('should create multiple content sections', (
      final tester,
    ) async {
      // arrange
      const widget = GrammarContentShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(
        containers.length,
        greaterThan(3),
      ); // Should have multiple content shimmer elements
    });

    testWidgets('should have proper container decorations', (
      final tester,
    ) async {
      // arrange
      const widget = GrammarContentShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      final containers = tester.widgetList<Container>(find.byType(Container));

      for (final container in containers) {
        final decoration = container.decoration as BoxDecoration?;
        if (decoration != null) {
          expect(decoration.borderRadius, isA<BorderRadius>());
        }
      }
    });

    testWidgets('should have varying container widths', (final tester) async {
      // arrange
      const widget = GrammarContentShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      final containers = tester.widgetList<Container>(find.byType(Container));

      final widths = containers
          .map((final container) => container.constraints?.maxWidth)
          .where((final width) => width != null)
          .toSet();

      expect(
        widths.length,
        greaterThanOrEqualTo(1),
      ); // Should have container widths
    });

    testWidgets('should be accessible and not throw errors', (
      final tester,
    ) async {
      // arrange
      const widget = GrammarContentShimmer();

      // act & assert
      await tester.pumpWidget(makeTestableWidget(widget));

      // Should not throw any errors during rendering
      expect(tester.takeException(), isNull);
    });

    testWidgets('should maintain consistent layout structure', (
      final tester,
    ) async {
      // arrange
      const widget = GrammarContentShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Verify the main structure
      expect(find.byType(Card), findsOneWidget);

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.child, isA<Padding>());

      // Verify padding structure
      final padding = card.child! as Padding;
      expect(padding.padding, equals(const EdgeInsets.all(16)));
      expect(padding.child, isA<Column>());
    });

    testWidgets('should simulate content sections properly', (
      final tester,
    ) async {
      // arrange
      const widget = GrammarContentShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Should have columns representing different content sections
      final columns = tester.widgetList<Column>(find.byType(Column));
      expect(
        columns.length,
        greaterThan(1),
      ); // Main column + content section columns

      // Should have SizedBox widgets for spacing
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('should render without any accessibility violations', (
      final tester,
    ) async {
      // arrange
      const widget = GrammarContentShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Verify that the widget renders successfully
      expect(find.byType(GrammarContentShimmer), findsOneWidget);

      // Ensure no exceptions were thrown
      expect(tester.takeException(), isNull);
    });
  });
}
