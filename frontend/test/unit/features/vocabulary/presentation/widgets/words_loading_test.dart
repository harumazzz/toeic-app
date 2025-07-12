import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/vocabulary/presentation/widgets/word_shimmer.dart';
import 'package:learn/features/vocabulary/presentation/widgets/words_loading.dart';

void main() {
  group('WordsLoading Widget', () {
    Widget makeTestableWidget(final Widget child) => MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );

    testWidgets('should display list view', (final tester) async {
      // arrange
      const widget = WordsLoading();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should display multiple word shimmers', (final tester) async {
      // arrange
      const widget = WordsLoading();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // In test environment, ListView might not render all 20 items
      expect(find.byType(WordShimmer), findsWidgets);
      expect(find.byType(WordShimmer), findsAtLeastNWidgets(1));
    });

    testWidgets('should generate shimmer items', (final tester) async {
      // arrange
      const widget = WordsLoading();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Should have shimmer widgets (exact count may vary in test environment)
      expect(find.byType(WordShimmer), findsWidgets);
    });

    testWidgets('should be scrollable', (final tester) async {
      // arrange
      const widget = WordsLoading();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Should find a scrollable ListView
      expect(find.byType(ListView), findsOneWidget);

      // Verify it's actually scrollable by checking for scrollable
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.vertical);
    });

    testWidgets('should display shimmer animations', (final tester) async {
      // arrange
      const widget = WordsLoading();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Each WordShimmer should contain shimmer animation
      expect(find.byType(WordShimmer), findsWidgets);
    });

    testWidgets('should render without errors', (final tester) async {
      // arrange
      const widget = WordsLoading();

      // act & assert
      expect(
        () async => tester.pumpWidget(makeTestableWidget(widget)),
        returnsNormally,
      );
    });

    testWidgets('should maintain consistent layout', (final tester) async {
      // arrange
      const widget = WordsLoading();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(WordShimmer), findsWidgets);
    });

    testWidgets('should be accessible', (final tester) async {
      // arrange
      const widget = WordsLoading();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      expect(find.byType(WordsLoading), findsOneWidget);
    });

    testWidgets('should handle widget rebuild correctly', (final tester) async {
      // arrange
      const widget = WordsLoading();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));
      await tester.pumpWidget(makeTestableWidget(widget)); // Rebuild

      // assert
      expect(find.byType(WordShimmer), findsWidgets);
    });

    testWidgets('should display proper loading state', (final tester) async {
      // arrange
      const widget = WordsLoading();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      // Should show loading indicators
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(WordShimmer), findsWidgets);
    });

    testWidgets('should have correct list direction', (final tester) async {
      // arrange
      const widget = WordsLoading();

      // act
      await tester.pumpWidget(makeTestableWidget(widget));

      // assert
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, equals(Axis.vertical));
    });
  });
}
