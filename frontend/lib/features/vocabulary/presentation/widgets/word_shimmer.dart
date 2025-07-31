import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class WordShimmer extends StatelessWidget {
  const WordShimmer({super.key});

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shimmerColor = colorScheme.brightness == Brightness.light
        ? Colors.grey[300]!
        : Colors.grey[700]!;
    
    return Padding(
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
                      interval: const Duration(milliseconds: 800),
                      color: colorScheme.surface,
                      child: Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Shimmer(
                    interval: const Duration(milliseconds: 800),
                    color: colorScheme.surface,
                    child: Container(
                      width: 70,
                      height: 28,
                      decoration: BoxDecoration(
                        color: shimmerColor,
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
                        interval: const Duration(milliseconds: 800),
                        color: colorScheme.surface,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Shimmer(
                        interval: const Duration(milliseconds: 800),
                        color: colorScheme.surface,
                        child: Container(
                          width: 80,
                          height: 16,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Shimmer(
                    interval: const Duration(milliseconds: 800),
                    color: colorScheme.surface,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Shimmer(
                interval: const Duration(milliseconds: 800),
                color: colorScheme.surface,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 20,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Shimmer(
                interval: const Duration(milliseconds: 800),
                color: colorScheme.surface,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 14,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
