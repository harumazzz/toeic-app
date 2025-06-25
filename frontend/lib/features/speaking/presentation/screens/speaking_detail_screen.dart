import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:record/record.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../shared/hooks/record_hook.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/speaking.dart';
import '../../domain/use_cases/create_speaking_session.dart';
import '../../domain/use_cases/create_speaking_turn.dart';

class SpeakingDetailScreen extends HookConsumerWidget {
  const SpeakingDetailScreen({
    super.key,
    required this.sessionId,
  });

  final int sessionId;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isNewSession = sessionId == -1;
    final audioRecorder = useAudioRecorder();
    final isRecording = useState(false);
    final conversation = useState<List<ConversationMessage>>([]);
    final currentSessionId = useState<int?>(sessionId == -1 ? null : sessionId);
    final isProcessing = useState(false);
    final sessionTopic = useState(context.t.speaking.sessionTopic);

    // Initialize with welcome message
    useEffect(() {
      if (conversation.value.isEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () async {
          if (context.mounted) {
            _addAIMessage(
              conversation,
              context.t.speaking.welcomeMessage,
            );
          }
        });
      }
      return null;
    }, []);

    Future<void> createNewSession() async {
      final authState = ref.read(authControllerProvider);
      if (authState is! AuthAuthenticated) {
        ToastService.error(
          context: context,
          message: context.t.speaking.loginRequired,
        );
        return;
      }

      try {
        final createSessionUseCase = ref.read(createSpeakingSessionProvider);
        final now = DateTime.now();
        final request = CreateSpeakingSessionRequest(
          speakingRequest: SpeakingRequest(
            userId: authState.user.id,
            sessionTopic: sessionTopic.value,
            startTime: now,
            endTime: now.add(const Duration(hours: 1)),
          ),
        );

        final result = await createSessionUseCase(request);
        result.fold(
          ifLeft: (final failure) {
            final failed = context.t.speaking.sessionCreationFailed;
            final message = '$failed: ${failure.message}';
            ToastService.error(
              context: context,
              message: message,
            );
          },
          ifRight: (final session) {
            currentSessionId.value = session.id;
            ToastService.success(
              context: context,
              message: context.t.speaking.sessionStartedSuccessfully,
            );
          },
        );
      } catch (e) {
        if (context.mounted) {
          ToastService.error(
            context: context,
            message: '${context.t.speaking.sessionCreationError}: $e',
          );
        }
      }
    }

    Future<void> startRecording() async {
      try {
        if (await audioRecorder.hasPermission()) {
          // Generate a unique filename for the recording
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final path = 'speaking_recording_$timestamp.aac';

          await audioRecorder.start(
            const RecordConfig(),
            path: path,
          );
          isRecording.value = true;
          if (context.mounted) {
            ToastService.info(
              context: context,
              message: context.t.speaking.recordingStarted,
            );
          }
        } else {
          if (context.mounted) {
            ToastService.error(
              context: context,
              message: context.t.speaking.recordingPermissionDenied,
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ToastService.error(
            context: context,
            message: '${context.t.speaking.recordingStartFailed}: $e',
          );
        }
      }
    }

    Future<void> stopRecording() async {
      try {
        final path = await audioRecorder.stop();
        isRecording.value = false;
        isProcessing.value = true;

        if (path != null) {
          // Simulate speech recognition (in a real app, you'd use a speech recognition service)
          await Future.delayed(const Duration(seconds: 2));

          // Mock user speech text
          final mockUserSpeech = _generateMockUserResponse();

          // Add user message to conversation
          _addUserMessage(conversation, mockUserSpeech, path);

          // Save turn to backend if session exists
          if (currentSessionId.value != null) {
            await _saveSpeakingTurn(
              ref,
              currentSessionId.value!,
              'user',
              mockUserSpeech,
              path,
            );
          }

          // Generate AI response
          await Future.delayed(const Duration(milliseconds: 500));
          final aiResponse = _generateAIResponse(mockUserSpeech);
          _addAIMessage(conversation, aiResponse);

          // Save AI turn to backend if session exists
          if (currentSessionId.value != null) {
            await _saveSpeakingTurn(
              ref,
              currentSessionId.value!,
              'ai',
              aiResponse,
              '',
            );
          }

          // Speak AI response
          await TTSService.speak(text: aiResponse);

          if (context.mounted) {
            ToastService.success(
              context: context,
              message: context.t.speaking.recordingCompleted,
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ToastService.error(
            context: context,
            message: '${context.t.speaking.speechProcessingFailed}: $e',
          );
        }
      } finally {
        isProcessing.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isNewSession
              ? context.t.speaking.newSession
              : context.t.speaking.sessionDetails,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          children: [
            // Session Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Symbols.mic,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sessionTopic.value,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isNewSession
                              ? context.t.speaking.newSession
                              // ignore: lines_longer_than_80_chars
                              : '${context.t.speaking.sessionNumber} ${currentSessionId.value}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isNewSession && currentSessionId.value == null)
                    ElevatedButton.icon(
                      onPressed: createNewSession,
                      icon: const Icon(Symbols.add),
                      label: Text(context.t.speaking.startSession),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                ],
              ),
            ),

            // Conversation Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child:
                    conversation.value.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Symbols.chat,
                                size: 64,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                context.t.speaking.waitingForConversation,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: conversation.value.length,
                          itemBuilder: (final context, final index) {
                            final message = conversation.value[index];
                            return _ConversationBubble(
                              message: message,
                              onPlayAudio: () {
                                if (message.isUser &&
                                    message.audioPath != null) {
                                  // Play recorded audio (implement audio player)
                                  ToastService.info(
                                    context: context,
                                    message: context.t.speaking.recordingPlayed,
                                  );
                                } else if (!message.isUser) {
                                  // Speak AI message
                                  TTSService.speak(text: message.text);
                                }
                              },
                            );
                          },
                        ),
              ),
            ),

            // Recording Controls
            Container(
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
                  if (isProcessing.value)
                    const LinearProgressIndicator()
                  else
                    Container(height: 4),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Recording button
                      GestureDetector(
                        onTap:
                            isProcessing.value
                                ? null
                                : (isRecording.value
                                    ? stopRecording
                                    : startRecording),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color:
                                isRecording.value
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isRecording.value
                                        ? Colors.red
                                        : Theme.of(context).colorScheme.primary)
                                    .withValues(alpha: 0.3),
                                blurRadius: 16,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            isRecording.value ? Symbols.stop : Symbols.mic,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isProcessing.value
                        ? context.t.speaking.processingYourSpeech
                        : isRecording.value
                        ? context.t.speaking.recordingTapToStop
                        : context.t.speaking.tapMicrophoneToStart,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addUserMessage(
    final ValueNotifier<List<ConversationMessage>> conversation,
    final String text,
    final String? audioPath,
  ) {
    conversation.value = [
      ...conversation.value,
      ConversationMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
        audioPath: audioPath,
      ),
    ];
  }

  void _addAIMessage(
    final ValueNotifier<List<ConversationMessage>> conversation,
    final String text,
  ) {
    conversation.value = [
      ...conversation.value,
      ConversationMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }

  String _generateMockUserResponse() {
    final responses = [
      "I'm feeling good today, thank you for asking.",
      "I'm a bit nervous but excited to practice.",
      "I'm doing well, ready to improve my English.",
      'I feel confident and motivated to learn.',
      "I'm okay, looking forward to this session.",
    ];
    return responses[Random().nextInt(responses.length)];
  }

  String _generateAIResponse(final String userMessage) {
    final responses = [
      "That's wonderful! A positive attitude is key to learning. Let me ask you: What do you enjoy doing in your free time?",
      'Great to hear! Now, can you tell me about your favorite hobby and why you enjoy it?',
      'Excellent! Speaking practice takes courage. Could you describe your ideal weekend activity?',
      'Perfect mindset for learning! What kind of books or movies do you prefer, and why?',
      "I'm glad you're here! Can you share what motivates you to improve your English skills?",
      "That's the spirit! Now, let's talk about food. What's your favorite dish and how is it prepared?",
      "Wonderful! Could you tell me about a memorable trip or place you'd like to visit?",
      'Great answer! What are some challenges people face when learning a new language?',
    ];
    return responses[Random().nextInt(responses.length)];
  }

  Future<void> _saveSpeakingTurn(
    final WidgetRef ref,
    final int sessionId,
    final String speakerType,
    final String textSpoken,
    final String audioPath,
  ) async {
    try {
      final createTurnUseCase = ref.read(createSpeakingTurnProvider);
      final request = CreateSpeakingTurnRequest(
        speakingTurnRequest: SpeakingTurnRequest(
          sessionId: sessionId,
          speakerType: speakerType,
          textSpoken: textSpoken,
          audioRecordingPath: audioPath,
          timestamp: DateTime.now(),
          aiEvaluation: const AiEvaluation(),
          aiScore:
              speakerType == 'user'
                  ? Random().nextInt(30) + 70
                  : 100, // Mock score
        ),
      );

      await createTurnUseCase(request);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save speaking turn: $e');
      }
    }
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('sessionId', sessionId));
  }
}

class ConversationMessage {
  const ConversationMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.audioPath,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? audioPath;
}

class _ConversationBubble extends StatelessWidget {
  const _ConversationBubble({
    required this.message,
    required this.onPlayAudio,
  });

  final ConversationMessage message;
  final VoidCallback onPlayAudio;

  @override
  Widget build(final BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    child: Row(
      mainAxisAlignment:
          message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
              color:
                  message.isUser
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft:
                    message.isUser
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                bottomRight:
                    message.isUser
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
                    color:
                        message.isUser
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            message.isUser
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
                        color:
                            message.isUser
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
