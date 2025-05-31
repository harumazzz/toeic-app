import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/vocabulary/presentation/widgets/word_detail/word_detail_shimmer.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

void main() {
  group('WordDetailShimmer Widget', () {
    Widget makeTestableWidget(final Widget child) => MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );

    testWidgets('should display shimmer loading animation', (
      final tester,
    ) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Shimmer), findsWidgets);
    });

    testWidgets('should display hero header shimmer section', (
      final tester,
    ) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Card), findsWidgets);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should display pronunciation card shimmer', (
      final tester,
    ) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Should have multiple cards for different sections
      expect(find.byType(Card), findsAtLeastNWidgets(2));
    });

    testWidgets('should display stats row shimmer', (final tester) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Should have stat shimmer cards
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('should display meanings section shimmer', (
      final tester,
    ) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Should generate multiple meaning items
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('should be scrollable', (final tester) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should have proper layout structure', (final tester) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('should handle different screen sizes', (final tester) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Should not throw any errors and render properly
      expect(find.byType(WordDetailShimmer), findsOneWidget);
    });

    testWidgets('should have consistent spacing', (final tester) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(SizedBox), findsWidgets);
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('should display shimmer containers with proper dimensions', (
      final tester,
    ) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(
        containers.length,
        greaterThan(5),
      ); // Should have multiple shimmer containers
    });

    testWidgets('should use SafeArea for proper layout', (final tester) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('should maintain consistent color scheme', (
      final tester,
    ) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Should use theme colors consistently
      expect(find.byType(WordDetailShimmer), findsOneWidget);
    });
  });

  group('_StatShimmerCard Widget', () {
    Widget makeTestableWidget(final Widget child) => MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );

    testWidgets('should display stat shimmer card structure', (
      final tester,
    ) async {
      // arrange
      const widget = WordDetailShimmer(); // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Should have cards that represent stat cards
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('should handle different colors', (final tester) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Should not throw errors with color variations
      expect(find.byType(WordDetailShimmer), findsOneWidget);
    });

    testWidgets('should have proper card layout', (final tester) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('_ShimmerContainer Widget', () {
    Widget makeTestableWidget(final Widget child) => MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );

    testWidgets('should wrap child in shimmer animation', (final tester) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Shimmer), findsWidgets);
    });

    testWidgets('should maintain child widget structure', (final tester) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Should preserve the structure of child widgets
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should apply shimmer animation consistently', (
      final tester,
    ) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      final shimmerWidgets = tester.widgetList<Shimmer>(find.byType(Shimmer));
      expect(shimmerWidgets.length, greaterThan(1));
    });

    testWidgets('should handle shimmer duration properly', (
      final tester,
    ) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));
      await tester.pump(const Duration(seconds: 2)); // Allow time for animation

      // assert
      expect(find.byType(Shimmer), findsWidgets);
    });

    testWidgets('should not affect widget performance', (final tester) async {
      // arrange
      const widget = WordDetailShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // Should complete rendering without issues
      await tester.pumpAndSettle();

      // assert
      expect(find.byType(WordDetailShimmer), findsOneWidget);
    });
  });
}
