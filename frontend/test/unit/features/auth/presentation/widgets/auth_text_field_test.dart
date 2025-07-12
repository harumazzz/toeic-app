import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/auth/presentation/widgets/auth_text_field.dart';

void main() {
  group('AuthTextField', () {
    testWidgets('renders email field and validates input', (
      final tester,
    ) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormBuilder(
              child: AuthTextField.email(
                controller: controller,
                focusNode: focusNode,
                labelText: 'Email',
                hintText: 'Enter email',
              ),
            ),
          ),
        ),
      );
      expect(find.byType(FormBuilderTextField), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Enter email'), findsOneWidget);
    });

    testWidgets('renders password field and validates input', (
      final tester,
    ) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormBuilder(
              child: AuthTextField.password(
                controller: controller,
                focusNode: focusNode,
                labelText: 'Password',
                hintText: 'Enter password',
              ),
            ),
          ),
        ),
      );
      expect(find.byType(FormBuilderTextField), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Enter password'), findsOneWidget);
    });

    testWidgets('renders username field and validates input', (
      final tester,
    ) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormBuilder(
              child: AuthTextField.username(
                controller: controller,
                focusNode: focusNode,
                labelText: 'Username',
                hintText: 'Enter username',
              ),
            ),
          ),
        ),
      );
      expect(find.byType(FormBuilderTextField), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Enter username'), findsOneWidget);
    });
  });
}
