import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../i18n/strings.g.dart';
import '../../../../shared/routes/app_router.dart';
import '../../domain/entities/speaking.dart';

class SpeakingSessionCard extends StatelessWidget {
  const SpeakingSessionCard({
    super.key,
    required this.session,
  });

  final Speaking session;

  @override
  Widget build(final BuildContext context) {
    String formatDuration(final DateTime start, final DateTime end) {
      final duration = end.difference(start);
      final minutes = duration.inMinutes;
      return '$minutes ${context.t.common.minutes}';
    }

    String formatDate(final DateTime date) => DateFormat(
      'MMM dd, yyyy',
    ).format(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap:
            () async =>
                SpeakingDetailRoute(sessionId: session.id).push(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.sessionTopic,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    formatDuration(session.startTime, session.endTime),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    formatDate(session.startTime),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Speaking>('session', session));
  }
}
