import 'package:flutter/material.dart';

import 'word_shimmer.dart';

class WordsLoading extends StatelessWidget {
  const WordsLoading({super.key});

  @override
  Widget build(final BuildContext context) => ListView(
    children: List.generate(
      20,
      (final int index) => const WordShimmer(),
    ),
  );
}
