import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../i18n/strings.g.dart';

class SessionInfoCard extends StatelessWidget {
  const SessionInfoCard({
    required this.sessionTopic,
    required this.isNewSession,
    required this.currentSessionId,
    required this.onCreateSession,
    super.key,
  });

  final String sessionTopic;
  final bool isNewSession;
  final int? currentSessionId;
  final VoidCallback onCreateSession;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Symbols.mic,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sessionTopic,
                  style:
                      Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isNewSession
                      ? context.t.speaking.newSession
                      : '${context.t.speaking.sessionNumber} $currentSessionId',
                  style:
                      Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (isNewSession && currentSessionId == null)
            ElevatedButton.icon(
              onPressed: onCreateSession,
              icon: const Icon(Symbols.add),
              label: Text(context.t.speaking.startSession),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('sessionTopic', sessionTopic))
      ..add(DiagnosticsProperty<bool>('isNewSession', isNewSession))
      ..add(IntProperty('currentSessionId', currentSessionId))
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onCreateSession',
          onCreateSession,
        ),
      );
  }
}
