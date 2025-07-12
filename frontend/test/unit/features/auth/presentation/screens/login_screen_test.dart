import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/auth/presentation/screens/login_screen.dart';
import 'package:learn/i18n/strings.g.dart';

void main() {
  testWidgets('LoginScreen renders fields and buttons', (final tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: TranslationProvider(
          child: const MaterialApp(home: LoginScreen()),
        ),
      ),
    );
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(FormBuilderTextField), findsNWidgets(2));
    expect(find.byType(FormBuilder), findsOneWidget);
    expect(find.byType(FilledButton), findsWidgets);
  });
}
