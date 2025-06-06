import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class GrammarContentShimmer extends StatelessWidget {
  const GrammarContentShimmer({super.key});

  @override
  Widget build(final BuildContext context) => Card(
    margin: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer(
            duration: const Duration(seconds: 2),
            color: Theme.of(context).colorScheme.surface,
            child: Container(
              width: 200,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            3,
            (final index) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer(
                  duration: const Duration(seconds: 2),
                  color: Theme.of(context).colorScheme.surface,
                  child: Container(
                    width: double.infinity,
                    height: 20,
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
                    width: 150,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  2,
                  (final index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Shimmer(
                      duration: const Duration(seconds: 2),
                      color: Theme.of(context).colorScheme.surface,
                      child: Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
