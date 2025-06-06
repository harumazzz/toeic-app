import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class GrammarListItemShimmer extends StatelessWidget {
  const GrammarListItemShimmer({super.key});

  @override
  Widget build(final BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer(
            duration: const Duration(seconds: 2),
            color: Theme.of(context).colorScheme.surface,
            child: Container(
              width: double.infinity,
              height: 24,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Shimmer(
            duration: const Duration(seconds: 2),
            color: Theme.of(context).colorScheme.surface,
            child: Container(
              width: 100,
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              3,
              (final index) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Shimmer(
                  duration: const Duration(seconds: 2),
                  color: Theme.of(context).colorScheme.surface,
                  child: Container(
                    width: 60,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
