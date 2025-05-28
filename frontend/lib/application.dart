import 'package:flutter/material.dart';

import 'shared/routes/app_router.dart';
import 'shared/theme/app_theme.dart';

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(final BuildContext context) => MaterialApp.router(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    routerConfig: router,
  );
}
