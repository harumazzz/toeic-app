import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';

class RecordingControls extends StatelessWidget {
  const RecordingControls({
    required this.isRecording,
    required this.isProcessing,
    required this.onStartRecording,
    required this.onStopRecording,
    super.key,
  });

  final bool isRecording;
  final bool isProcessing;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  @override
  Widget build(final BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: Column(
      children: [
        if (isProcessing)
          const LinearProgressIndicator()
        else
          Container(height: 4),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Recording button
            GestureDetector(
              onTap: isProcessing
                  ? null
                  : (isRecording ? onStopRecording : onStartRecording),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isRecording
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isRecording
                                  ? Colors.red
                                  : Theme.of(context).colorScheme.primary)
                              .withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  isRecording ? Symbols.stop : Symbols.mic,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          isProcessing
              ? context.t.speaking.processingYourSpeech
              : isRecording
              ? context.t.speaking.recordingTapToStop
              : context.t.speaking.tapMicrophoneToStart,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('isRecording', isRecording))
      ..add(DiagnosticsProperty<bool>('isProcessing', isProcessing))
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onStartRecording',
          onStartRecording,
        ),
      )
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onStopRecording',
          onStopRecording,
        ),
      );
  }
}
