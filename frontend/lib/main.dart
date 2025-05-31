import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'i18n/strings.g.dart';
import 'injection_container.dart';
import 'shared/routes/app_router.dart';
import 'shared/theme/app_theme.dart';

Future<void> main(
  final List<String> arguments,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(
    ProviderScope(
      child: TranslationProvider(
        child: const Main(),
      ),
    ),
  );
}

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(final BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    routerConfig: AppRouter.router,
  );
}
