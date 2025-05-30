import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/secure_storage_service.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/vocabulary/presentation/pages/vocabulary_page.dart';
import '../../injection_container.dart';

part 'app_router.g.dart';

class AppRouter {
  const AppRouter._();

  static const String loginRoute = 'login';

  static const String registerRoute = 'register';

  static const String forgotPasswordRoute = 'forgot-password';

  static const String homeRoute = 'home';

  static const String vocabularyRoute = 'vocabulary';

  static GoRouter get router => _router;
}

@TypedGoRoute<LoginRoute>(
  path: '/${AppRouter.loginRoute}',
  name: AppRouter.loginRoute,
)
class LoginRoute extends GoRouteData {
  const LoginRoute();

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => const LoginPage();
}

@TypedGoRoute<RegisterRoute>(
  path: '/${AppRouter.registerRoute}',
  name: AppRouter.registerRoute,
)
class RegisterRoute extends GoRouteData {
  const RegisterRoute();

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => const RegisterPage();
}

@TypedGoRoute<ForgotPasswordRoute>(
  path: '/${AppRouter.forgotPasswordRoute}',
  name: AppRouter.forgotPasswordRoute,
)
class ForgotPasswordRoute extends GoRouteData {
  const ForgotPasswordRoute();

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => const Scaffold(body: Center(child: Text('Forgot Password Screen')));
}

@TypedGoRoute<HomeRoute>(
  path: '/${AppRouter.homeRoute}',
  name: AppRouter.homeRoute,
)
class HomeRoute extends GoRouteData {
  const HomeRoute();

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => const HomePage();
}

@TypedGoRoute<VocabularyRoute>(
  path: '/${AppRouter.vocabularyRoute}',
  name: AppRouter.vocabularyRoute,
)
class VocabularyRoute extends GoRouteData {
  const VocabularyRoute();

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => const VocabularyPage();
}

final GoRouter _router = GoRouter(
  routes: $appRoutes,
  initialLocation: '/${AppRouter.loginRoute}',
  debugLogDiagnostics: kDebugMode,
  redirect: (final context, final state) async {
    final token =
        await InjectionContainer.get<SecureStorageService>().getAccessToken();
    if (token == null || token.isEmpty) {
      return '/${AppRouter.loginRoute}';
    }
    final path = state.uri.toString();
    switch (path) {
      case '/${AppRouter.loginRoute}':
      case '/${AppRouter.registerRoute}':
      case '/${AppRouter.forgotPasswordRoute}':
        return '/${AppRouter.homeRoute}';
    }
    return path;
  },
);
