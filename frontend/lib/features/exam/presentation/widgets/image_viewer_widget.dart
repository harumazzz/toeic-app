import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

class ImageViewerWidget extends HookConsumerWidget {
  const ImageViewerWidget({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  final String imageUrl;
  final String title;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    Future<void> showFullScreenImage() async {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (final context) => FullScreenImageViewer(
                imageUrl: imageUrl,
                title: title,
              ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Symbols.image,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Tap to view full size',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: showFullScreenImage,
                  icon: const Icon(
                    Symbols.fullscreen,
                    color: Colors.green,
                  ),
                  tooltip: 'View Full Size',
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: showFullScreenImage,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                maxHeight: 200,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (
                    final context,
                    final child,
                    final loadingProgress,
                  ) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Loading image...',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  errorBuilder:
                      (final context, final error, final stackTrace) =>
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Symbols.broken_image,
                                    size: 48,
                                    color: Colors.red.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Failed to load image',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color: Colors.red.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to retry',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color: Colors.red.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('imageUrl', imageUrl))
      ..add(StringProperty('title', title));
  }
}

class FullScreenImageViewer extends HookConsumerWidget {
  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  final String imageUrl;
  final String title;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final transformationController = useTransformationController();
    final isZoomed = useState(false);

    void resetZoom() {
      transformationController.value = Matrix4.identity();
      isZoomed.value = false;
    }

    void handleDoubleTap() {
      if (isZoomed.value) {
        resetZoom();
      } else {
        transformationController.value = Matrix4.identity()..scale(2.0);
        isZoomed.value = true;
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: resetZoom,
            icon: const Icon(Symbols.zoom_out_map),
            tooltip: 'Reset Zoom',
          ),
        ],
      ),
      body: Center(
        child: GestureDetector(
          onDoubleTap: handleDoubleTap,
          child: InteractiveViewer(
            transformationController: transformationController,
            minScale: 0.5,
            maxScale: 4,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (
                final context,
                final child,
                final loadingProgress,
              ) {
                if (loadingProgress == null) {
                  return child;
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Loading image...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
              errorBuilder:
                  (final context, final error, final stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Symbols.broken_image,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Text(
          'Double tap to zoom • Pinch to zoom • Drag to pan',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('imageUrl', imageUrl))
      ..add(StringProperty('title', title));
  }
}
