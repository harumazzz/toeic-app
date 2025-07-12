import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/auth/domain/entities/user.dart';
import 'package:learn/features/auth/presentation/providers/auth_provider.dart';
import 'package:learn/features/auth/presentation/widgets/auth_action_buttons.dart';
import 'package:mocktail/mocktail.dart';

class Listener extends Mock {
  void call();
}

void main() {
  group('AuthActionButton', () {
    late VoidCallback onPrimaryPressed;
    late VoidCallback onSecondaryPressed;

    setUp(() {
      onPrimaryPressed = Listener().call;
      onSecondaryPressed = Listener().call;
    });

    Future<void> pumpWithState(
      final WidgetTester tester,
      final AuthState state,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => _FakeAuthController(state),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AuthActionButton(
                primaryButtonText: 'Login',
                secondaryButtonText: 'Register',
                onPrimaryPressed: onPrimaryPressed,
                onSecondaryPressed: onSecondaryPressed,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows primary button for AuthInitial', (final tester) async {
      await pumpWithState(tester, const AuthState.initial());
      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(FilledButton), findsNWidgets(2));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows primary button for AuthUnauthenticated', (
      final tester,
    ) async {
      await pumpWithState(tester, const AuthState.unauthenticated());
      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(FilledButton), findsNWidgets(2));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows primary button for AuthError', (final tester) async {
      await pumpWithState(tester, const AuthState.error(message: 'error'));
      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(FilledButton), findsNWidgets(2));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows CircularProgressIndicator for AuthLoading', (
      final tester,
    ) async {
      await pumpWithState(tester, const AuthState.loading());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget); // Only secondary
    });

    testWidgets('shows CircularProgressIndicator for AuthAuthenticated', (
      final tester,
    ) async {
      await pumpWithState(
        tester,
        const AuthState.authenticated(
          user: User(id: 1, email: 'a', username: 'b'),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget); // Only secondary
    });

    testWidgets('calls onPrimaryPressed and onSecondaryPressed', (
      final tester,
    ) async {
      await pumpWithState(tester, const AuthState.initial());
      await tester.tap(find.text('Login'));
      await tester.tap(find.text('Register'));
      verify(() => onPrimaryPressed()).called(1);
      verify(() => onSecondaryPressed()).called(1);
    });
  });
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}
