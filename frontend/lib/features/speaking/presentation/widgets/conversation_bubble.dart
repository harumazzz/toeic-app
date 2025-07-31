import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';
import '../../domain/entities/evaluation.dart';

class EvaluationWidget extends StatelessWidget {
  const EvaluationWidget({
    required this.evaluation,
    super.key,
  });

  final SpeakingEvaluation evaluation;

  @override
  Widget build(final BuildContext context) {
    final score = evaluation.overallScore;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.grade,
                size: 16,
                color: _getScoreColor(context, score),
              ),
              const SizedBox(width: 4),
              Text(
                context.t.speaking.scoreOutOf100.replaceAll(
                  '{score}',
                  score.toString(),
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (evaluation.feedback != null) ...[
            const SizedBox(height: 4),
            Text(
              evaluation.feedback!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getScoreColor(final BuildContext context, final int score) {
    final colorScheme = Theme.of(context).colorScheme;

    if (score >= 80) {
      return colorScheme.tertiary; // Green equivalent
    }
    if (score >= 60) {
      return colorScheme.secondary; // Orange equivalent
    }
    return colorScheme.error; // Red equivalent
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<SpeakingEvaluation>('evaluation', evaluation),
    );
  }
}

class ConversationMessage {
  const ConversationMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.audioPath,
    this.evaluation,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? audioPath;
  final SpeakingEvaluation? evaluation;
}

class ConversationBubble extends StatelessWidget {
  const ConversationBubble({
    required this.message,
    required this.onPlayAudio,
    super.key,
  });

  final ConversationMessage message;
  final VoidCallback onPlayAudio;

  @override
  Widget build(final BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    child: Row(
      mainAxisAlignment: message.isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!message.isUser) ...[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Symbols.smart_toy,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: message.isUser
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: message.isUser
                    ? const Radius.circular(16)
                    : const Radius.circular(4),
                bottomRight: message.isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: message.isUser
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (message.evaluation != null && message.isUser) ...[
                  const SizedBox(height: 8),
                  EvaluationWidget(evaluation: message.evaluation!),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${message.timestamp.hour.toString().padLeft(
                        2,
                        '0',
                      )}:${message.timestamp.minute.toString().padLeft(
                        2,
                        '0',
                      )}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: message.isUser
                            ? Theme.of(
                                context,
                              ).colorScheme.onPrimary.withValues(alpha: 0.7)
                            : Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onPlayAudio,
                      child: Icon(
                        Symbols.volume_up,
                        size: 16,
                        color: message.isUser
                            ? Theme.of(
                                context,
                              ).colorScheme.onPrimary.withValues(alpha: 0.7)
                            : Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (message.isUser) ...[
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Symbols.person,
              color: Theme.of(context).colorScheme.onSecondary,
              size: 18,
            ),
          ),
        ],
      ],
    ),
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<ConversationMessage>('message', message),
      )
      ..add(
        ObjectFlagProperty<VoidCallback>.has('onPlayAudio', onPlayAudio),
      );
  }
}
