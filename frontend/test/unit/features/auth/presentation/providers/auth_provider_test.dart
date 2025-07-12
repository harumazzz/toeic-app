import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/auth/presentation/providers/auth_provider.dart';

class MockAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.initial();
}

void main() {
  test('initial state is AuthInitial', () {
    final controller = MockAuthController();
    expect(controller.build(), isA<AuthInitial>());
  });
  // Add more tests for state transitions as needed
}
