import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class WordsLoading extends StatelessWidget {
  const WordsLoading({super.key});

  @override
  Widget build(final BuildContext context) => ListView(
    children: List.generate(
      20,
      (final int index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Shimmer(
                        duration: const Duration(seconds: 2),
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Shimmer(
                      duration: const Duration(seconds: 2),
                      child: Container(
                        width: 70,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Shimmer(
                          duration: const Duration(seconds: 2),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Shimmer(
                          duration: const Duration(seconds: 2),
                          child: Container(
                            width: 80,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Shimmer(
                      duration: const Duration(seconds: 2),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Shimmer(
                  duration: const Duration(seconds: 2),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Shimmer(
                  duration: const Duration(seconds: 2),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
