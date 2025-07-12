import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/grammars/presentation/widgets/grammar_list_item_shimmer.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

void main() {
  group('GrammarListItemShimmer Widget', () {
    Widget makeTestableWidget(final Widget child) => MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );

    testWidgets('should render shimmer widget correctly', (
      final tester,
    ) async {
      // arrange
      const widget = GrammarListItemShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Shimmer), findsWidgets);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should have correct card styling', (final tester) async {
      // arrange
      const widget = GrammarListItemShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      final card = tester.widget<Card>(find.byType(Card));
      expect(
        card.margin,
        equals(const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
      );
    });

    testWidgets('should have proper layout structure', (final tester) async {
      // arrange
      const widget = GrammarListItemShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('should display multiple shimmer containers', (
      final tester,
    ) async {
      // arrange
      const widget = GrammarListItemShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Should have multiple shimmer effects for different UI elements
      expect(find.byType(Shimmer), findsAtLeastNWidgets(3));
      expect(find.byType(Container), findsAtLeastNWidgets(3));
    });

    testWidgets('should have shimmer animations with correct duration', (
      final tester,
    ) async {
      // arrange
      const widget = GrammarListItemShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      final shimmerWidgets = tester.widgetList<Shimmer>(find.byType(Shimmer));

      for (final shimmer in shimmerWidgets) {
        expect(shimmer.duration, equals(const Duration(seconds: 2)));
      }
    });

    testWidgets('should have containers with border radius', (
      final tester,
    ) async {
      // arrange
      const widget = GrammarListItemShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      final containerWidgets = tester.widgetList<Container>(
        find.byType(Container),
      );

      for (final container in containerWidgets) {
        if (container.decoration is BoxDecoration) {
          final decoration = container.decoration! as BoxDecoration;
          expect(decoration.borderRadius, isA<BorderRadius>());
        }
      }
    });

    testWidgets('should not crash when rendered', (final tester) async {
      // arrange
      const widget = GrammarListItemShimmer();

      // act & assert
      await expectLater(
        () => tester.pumpWidget(makeTestableWidget(widget)),
        returnsNormally,
      );
    });

    testWidgets('should have proper spacing between elements', (
      final tester,
    ) async {
      // arrange
      const widget = GrammarListItemShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(sizedBoxes.length, greaterThan(0));

      // Check that SizedBox widgets have proper height values
      final heightValues = sizedBoxes
          .map((final box) => box.height)
          .where((final height) => height != null)
          .toList();
      expect(heightValues, isNotEmpty);
    });
  });
}
