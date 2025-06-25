import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/secure_storage_service.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/exam/presentation/screens/exam_screen.dart';
import '../../features/grammars/presentation/screens/grammar_detail_screen.dart';
import '../../features/grammars/presentation/screens/grammar_list_screen.dart';
import '../../features/help/presentation/screens/help_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/practice/presentation/screens/practice_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/settings/presentation/screens/setting_screen.dart';
import '../../features/speaking/presentation/screens/speaking_detail_screen.dart';
import '../../features/speaking/presentation/screens/speaking_screen.dart';
import '../../features/vocabulary/presentation/screens/vocabulary_screen.dart';
import '../../features/vocabulary/presentation/screens/word_detail_screen.dart';
import '../../features/writing/presentation/screens/drafts_management_screen.dart';
import '../../features/writing/presentation/screens/practice_writing_screen.dart';
import '../../features/writing/presentation/screens/writing_detail_screen.dart';
import '../../features/writing/presentation/screens/writing_screen.dart';
import '../../features/writing/presentation/screens/writing_submission_success_screen.dart';
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

  static const String practiceRoute = 'practice';

  static const String progressRoute = 'progress';

  static const String speakingRoute = 'speaking';

  static const String speakingDetailRoute = 'speaking-detail';

  static const String writingRoute = 'writing';

  static const String examsRoute = 'exams';

  static const String practiceWritingRoute = 'practice-writing';

  static const String writingSubmissionSuccessRoute =
      'writing-submission-success';

  static const String draftsManagementRoute = 'drafts-management';

  static const String writingDetailRoute = 'writing-detail';

  static GoRouter get router => _router;
}

@TypedGoRoute<LoginRoute>(
  path: '/${AppRouter.loginRoute}',
  name: AppRouter.loginRoute,
)
class LoginRoute extends GoRouteData with _$LoginRoute {
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
class RegisterRoute extends GoRouteData with _$RegisterRoute {
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
class ForgotPasswordRoute extends GoRouteData with _$ForgotPasswordRoute {
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
class HomeRoute extends GoRouteData with _$HomeRoute {
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
class HelpRoute extends GoRouteData with _$HelpRoute {
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
class VocabularyRoute extends GoRouteData with _$VocabularyRoute {
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
class WordDetailRoute extends GoRouteData with _$WordDetailRoute {
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
class GrammarRoute extends GoRouteData with _$GrammarRoute {
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
class GrammarDetailRoute extends GoRouteData with _$GrammarDetailRoute {
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
class SettingsRoute extends GoRouteData with _$SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => const SettingScreen();
}

@TypedGoRoute<PracticeRoute>(
  path: '/${AppRouter.practiceRoute}',
  name: AppRouter.practiceRoute,
)
class PracticeRoute extends GoRouteData with _$PracticeRoute {
  const PracticeRoute();

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => const PracticeScreen();
}

@TypedGoRoute<ProgressRoute>(
  path: '/${AppRouter.progressRoute}',
  name: AppRouter.progressRoute,
)
class ProgressRoute extends GoRouteData with _$ProgressRoute {
  const ProgressRoute();

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => const ProgressScreen();
}

@TypedGoRoute<SpeakingRoute>(
  path: '/${AppRouter.speakingRoute}',
  name: AppRouter.speakingRoute,
)
class SpeakingRoute extends GoRouteData with _$SpeakingRoute {
  const SpeakingRoute();

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => const SpeakingScreen();
}

@TypedGoRoute<SpeakingDetailRoute>(
  path: '/${AppRouter.speakingDetailRoute}/:sessionId',
  name: AppRouter.speakingDetailRoute,
)
class SpeakingDetailRoute extends GoRouteData with _$SpeakingDetailRoute {
  const SpeakingDetailRoute({
    required this.sessionId,
  });

  final int sessionId;

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => SpeakingDetailScreen(sessionId: sessionId);
}

@TypedGoRoute<WritingRoute>(
  path: '/${AppRouter.writingRoute}',
  name: AppRouter.writingRoute,
)
class WritingRoute extends GoRouteData with _$WritingRoute {
  const WritingRoute();

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => const WritingScreen();
}

@TypedGoRoute<ExamRoute>(
  path: '/${AppRouter.examsRoute}',
  name: AppRouter.examsRoute,
)
class ExamRoute extends GoRouteData with _$ExamRoute {
  const ExamRoute(this.examId);

  final int examId;

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => ExamScreen(examId: examId);
}

@TypedGoRoute<PracticeWritingRoute>(
  path: '/${AppRouter.practiceWritingRoute}',
  name: AppRouter.practiceWritingRoute,
)
class PracticeWritingRoute extends GoRouteData with _$PracticeWritingRoute {
  const PracticeWritingRoute({
    this.prompt,
    this.promptId,
  });

  final String? prompt;
  final int? promptId;

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => PracticeWritingScreen(
    prompt: prompt,
    promptId: promptId,
  );
}

@TypedGoRoute<WritingDetailRoute>(
  path: '/${AppRouter.writingDetailRoute}/:promptId',
  name: AppRouter.writingDetailRoute,
)
class WritingDetailRoute extends GoRouteData with _$WritingDetailRoute {
  const WritingDetailRoute({
    required this.promptId,
  });

  final int promptId;
  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => WritingDetailScreen(promptId: promptId);
}

@TypedGoRoute<WritingSubmissionSuccessRoute>(
  path: '/${AppRouter.writingSubmissionSuccessRoute}',
  name: AppRouter.writingSubmissionSuccessRoute,
)
class WritingSubmissionSuccessRoute extends GoRouteData
    with _$WritingSubmissionSuccessRoute {
  const WritingSubmissionSuccessRoute({
    required this.wordCount,
    required this.content,
    this.prompt,
  });

  final int wordCount;
  final String content;
  final String? prompt;

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => WritingSubmissionSuccessScreen(
    wordCount: wordCount,
    content: content,
    prompt: prompt,
  );
}

@TypedGoRoute<DraftsManagementRoute>(
  path: '/${AppRouter.draftsManagementRoute}',
  name: AppRouter.draftsManagementRoute,
)
class DraftsManagementRoute extends GoRouteData with _$DraftsManagementRoute {
  const DraftsManagementRoute();

  @override
  Widget build(
    final BuildContext context,
    final GoRouterState state,
  ) => const DraftsManagementScreen();
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
