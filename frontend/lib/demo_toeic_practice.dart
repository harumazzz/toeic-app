import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/speaking/presentation/screens/toeic_practice_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context) => MaterialApp(
    title: 'TOEIC Practice Demo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
    ),
    home: const ToeicPracticeScreen(),
  );
}
