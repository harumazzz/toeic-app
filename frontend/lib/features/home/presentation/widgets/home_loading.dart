import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class HomeLoading extends StatelessWidget {
  const HomeLoading({super.key});

  @override
  Widget build(final BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Shimmer(
        duration: const Duration(seconds: 2),
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.4,
          height: MediaQuery.sizeOf(context).width * 0.4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    ],
  );
}
