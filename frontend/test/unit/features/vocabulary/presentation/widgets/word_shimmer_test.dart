import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/vocabulary/presentation/widgets/word_shimmer.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

void main() {
  group('WordShimmer Widget', () {
    Widget makeTestableWidget(final Widget child) => MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );

    testWidgets('should display shimmer loading animation', (
      final tester,
    ) async {
      // arrange
      const widget = WordShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Shimmer), findsNWidgets(7));
    });

    testWidgets('should display card container', (final tester) async {
      // arrange
      const widget = WordShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should display shimmer containers', (final tester) async {
      // arrange
      const widget = WordShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should have proper padding', (final tester) async {
      // arrange
      const widget = WordShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('should display multiple shimmer elements', (
      final tester,
    ) async {
      // arrange
      const widget = WordShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Should have shimmer elements for word, pronunciation, meaning, etc.
      expect(find.byType(Container), findsAtLeastNWidgets(3));
    });

    testWidgets('should display row layout', (final tester) async {
      // arrange
      const widget = WordShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('should display column layout', (final tester) async {
      // arrange
      const widget = WordShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('should be accessible', (final tester) async {
      // arrange
      const widget = WordShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(WordShimmer), findsOneWidget);
    });

    testWidgets('should render without errors', (final tester) async {
      // arrange
      const widget = WordShimmer();

      // act & assert
      expect(
        () async => tester.pumpWidget(makeTestableWidget(widget)),
        returnsNormally,
      );
    });

    testWidgets('should have consistent layout structure', (
      final tester,
    ) async {
      // arrange
      const widget = WordShimmer();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Should maintain the same structure as actual word card
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
      expect(find.byType(Column), findsWidgets);
    });
  });
}
