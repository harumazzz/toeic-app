import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/secure_storage_service.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/grammars/presentation/screens/grammar_detail_screen.dart';
import '../../features/grammars/presentation/screens/grammar_list_screen.dart';
import '../../features/help/presentation/screens/help_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/setting_screen.dart';
import '../../features/vocabulary/presentation/screens/vocabulary_screen.dart';
import '../../features/vocabulary/presentation/screens/word_detail_screen.dart';
import '../../injection_container.dart';

part 'app_router.g.dart';

class AppRouter {
  const AppRouter._();

  static const String loginRoute = 'login';

  static const String registerRoute = 'register';

  static const String forgotPasswordRoute = 'forgot-password';

  static const String homeRoute = 'home';

  static const String helpRoute = 'help';

  static const String vocabularyRoute = 'vocabulary';

  static const String wordDetailRoute = 'word-detail';

  static const String grammarRoute = 'grammar';

  static const String grammarDetailRoute = 'grammar-detail';

  static const String settingsRoute = 'settings';

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
  ) => const LoginScreen();
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
  ) => const RegisterScreen();
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
  ) => const HomeScreen();
}

@TypedGoRoute<HelpRoute>(
  path: '/${AppRouter.helpRoute}',
  name: AppRouter.helpRoute,
)
class HelpRoute extends GoRouteData {
  const HelpRoute();

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => const HelpScreen();
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
  ) => const VocabularyScreen();
}

@TypedGoRoute<WordDetailRoute>(
  path: '/${AppRouter.wordDetailRoute}/:wordId',
  name: AppRouter.wordDetailRoute,
)
class WordDetailRoute extends GoRouteData {
  const WordDetailRoute({
    required this.wordId,
  });

  final int wordId;

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => WordDetailScreen(wordId: wordId);
}

@TypedGoRoute<GrammarRoute>(
  path: '/${AppRouter.grammarRoute}',
  name: AppRouter.grammarRoute,
)
class GrammarRoute extends GoRouteData {
  const GrammarRoute();

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => const GrammarListScreen();
}

@TypedGoRoute<GrammarDetailRoute>(
  path: '/${AppRouter.grammarDetailRoute}/:grammarId',
  name: AppRouter.grammarDetailRoute,
)
class GrammarDetailRoute extends GoRouteData {
  const GrammarDetailRoute({required this.grammarId});

  final int grammarId;

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => GrammarDetailScreen(grammarId: grammarId);
}

@TypedGoRoute<SettingsRoute>(
  path: '/${AppRouter.settingsRoute}',
  name: AppRouter.settingsRoute,
)
class SettingsRoute extends GoRouteData {
  const SettingsRoute();

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => const SettingScreen();
}

final GoRouter _router = GoRouter(
  routes: $appRoutes,
  initialLocation: '/${AppRouter.loginRoute}',
  debugLogDiagnostics: kDebugMode,
  redirect: (final context, final state) async {
    final secureStorage = InjectionContainer.get<SecureStorageService>();
    final token = await secureStorage.getAccessToken();
    final isExpired = await secureStorage.isExpired();
    if (token == null || token.isEmpty || isExpired) {
      if (isExpired) {
        await secureStorage.clearAllTokens();
      }
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
