import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:learn/features/auth/presentation/widgets/auth_header.dart';

void main() {
  group('AuthHeader', () {
    const tTitle = 'Test Title';
    const tSubtitle = 'Test Subtitle';

    testWidgets('should display title and subtitle correctly', (
      final tester,
    ) async {
      // arrange
      const authHeader = AuthHeader(
        title: tTitle,
        subtitle: tSubtitle,
      );

      // act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: authHeader),
        ),
      );

      // assert
      expect(find.text(tTitle), findsOneWidget);
      expect(find.text(tSubtitle), findsOneWidget);
    });

    testWidgets('should have correct text styles', (final tester) async {
      // arrange
      const authHeader = AuthHeader(
        title: tTitle,
        subtitle: tSubtitle,
      );

      // act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: authHeader),
        ),
      );

      // assert
      final titleWidget = tester.widget<Text>(find.text(tTitle));
      final subtitleWidget = tester.widget<Text>(find.text(tSubtitle));

      expect(titleWidget.style?.fontWeight, FontWeight.bold);
      expect(subtitleWidget.textAlign, TextAlign.center);
    });

    testWidgets('should be arranged in a column', (final tester) async {
      // arrange
      const authHeader = AuthHeader(
        title: tTitle,
        subtitle: tSubtitle,
      );

      // act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: authHeader),
        ),
      );

      // assert
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(SizedBox), findsNWidgets(2)); // spacing elements
    });

    testWidgets('should display empty strings correctly', (final tester) async {
      // arrange
      const authHeader = AuthHeader(
        title: '',
        subtitle: '',
      );

      // act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: authHeader),
        ),
      );

      // assert
      expect(find.byType(Text), findsNWidgets(2));
      expect(find.text(''), findsNWidgets(2));
    });

    testWidgets('should handle long text content', (final tester) async {
      // arrange
      const longTitle =
          'This is a very long title that might wrap to multiple lines';
      const longSubtitle =
          // ignore: lines_longer_than_80_chars
          'This is a very long subtitle that definitely should wrap to multiple lines and test text overflow behavior';

      const authHeader = AuthHeader(
        title: longTitle,
        subtitle: longSubtitle,
      );

      // act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: authHeader),
        ),
      );

      // assert
      expect(find.text(longTitle), findsOneWidget);
      expect(find.text(longSubtitle), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('should maintain proper spacing between elements', (
      final tester,
    ) async {
      // arrange
      const authHeader = AuthHeader(
        title: tTitle,
        subtitle: tSubtitle,
      );

      // act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: authHeader),
        ),
      );

      // assert
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(sizedBoxes.length, 2);

      final spacingBoxes =
          sizedBoxes.where((final box) => box.height != null).toList();
      expect(
        spacingBoxes.first.height,
        8.0,
      ); // spacing between title and subtitle
      expect(spacingBoxes.last.height, 16.0); // spacing after subtitle
    });
  });
}
