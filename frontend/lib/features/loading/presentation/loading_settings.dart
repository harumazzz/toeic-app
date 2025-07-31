import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import '../../../i18n/strings.g.dart';

class LoadingSettings extends StatelessWidget {
  const LoadingSettings({
    super.key,
  });

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLightMode = colorScheme.brightness == Brightness.light;
    final background = isLightMode ? Colors.grey.shade50 : colorScheme.surface;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: background,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isLightMode
                  ? [
                      Colors.blue.shade50,
                      Colors.indigo.shade50,
                      Colors.purple.shade50,
                    ]
                  : [
                      colorScheme.surface,
                      colorScheme.surfaceContainer,
                      colorScheme.surfaceContainerHigh,
                    ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Shimmer(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Symbols.settings,
                              size: 32,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Shimmer(
                        duration: const Duration(seconds: 2),
                        color: isLightMode
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                        child: Text(
                          context.t.settings.loading,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                left: i > 0 ? 8.0 : 0,
                              ),
                              child: Shimmer(
                                duration: Duration(
                                  milliseconds: 800 + (i * 200),
                                ),
                                color: colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Shimmer(
                  duration: const Duration(seconds: 2, milliseconds: 500),
                  color: colorScheme.surface.withValues(alpha: 0.8),
                  child: Text(
                    context.t.app.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
