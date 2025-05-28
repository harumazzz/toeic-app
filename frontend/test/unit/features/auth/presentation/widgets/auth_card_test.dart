import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:learn/features/auth/presentation/widgets/auth_card.dart';

void main() {
  group('AuthCard', () {
    testWidgets('should display children correctly', (final tester) async {
      // arrange
      const testChild1 = Text('Test Child 1');
      const testChild2 = Text('Test Child 2');
      const authCard = AuthCard(
        children: [testChild1, testChild2],
      );

      // act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: authCard),
        ),
      );

      // assert
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Test Child 1'), findsOneWidget);
      expect(find.text('Test Child 2'), findsOneWidget);
    });

    testWidgets('should be centered on screen', (final tester) async {
      // arrange
      const authCard = AuthCard(
        children: [Text('Test')],
      );

      // act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: authCard),
        ),
      );

      // assert
      expect(find.byType(Center), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should have proper margin and padding', (final tester) async {
      // arrange
      const authCard = AuthCard(
        children: [Text('Test')],
      );

      // act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: authCard),
        ),
      );

      // assert
      final cardWidget = tester.widget<Card>(find.byType(Card));
      expect(
        cardWidget.margin,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      );
    });

    testWidgets('should display column with children and spacing', (
      final tester,
    ) async {
      // arrange
      const authCard = AuthCard(
        children: [Text('Test')],
      );

      // act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: authCard),
        ),
      );

      // assert
      expect(find.byType(Column), findsOneWidget);
      final columnWidget = tester.widget<Column>(find.byType(Column));
      expect(columnWidget.mainAxisAlignment, MainAxisAlignment.center);
      expect(columnWidget.mainAxisSize, MainAxisSize.min);
    });

    testWidgets('should handle empty children list', (final tester) async {
      // arrange
      const authCard = AuthCard(
        children: [],
      );

      // act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: authCard),
        ),
      );

      // assert
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('should handle multiple children', (final tester) async {
      // arrange
      final children = List.generate(5, (final index) => Text('Child $index'));
      final authCard = AuthCard(children: children);

      // act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: authCard),
        ),
      );

      // assert
      expect(find.byType(Card), findsOneWidget);
      for (int i = 0; i < 5; i++) {
        expect(find.text('Child $i'), findsOneWidget);
      }
    });
  });
}
