import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/services/ai_response_service.dart';
import '../../../../core/services/speech_to_text_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../shared/hooks/record_hook.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/speaking.dart';
import '../../domain/use_cases/create_speaking_session.dart';
import '../../domain/use_cases/create_speaking_turn.dart';
import '../widgets/conversation_bubble.dart';
import '../widgets/recording_controls.dart';
import '../widgets/session_info_card.dart';

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
    final aiResponseService = ref.read(aiResponseServiceProvider);
    final recognizedText = useState('');
    final isListening = useState(false);

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
          debugPrint('Audio recording permission granted');

          // Request speech recognition permission explicitly
          final speechPermission =
              await SpeechToTextService.requestPermission();
          debugPrint('Speech recognition permission: $speechPermission');

          if (!speechPermission && context.mounted) {
            ToastService.error(
              context: context,
              message: context.t.speaking.speechRecognitionPermissionRequired,
            );
            return;
          }

          debugPrint(
            'Permissions granted for audio recording and speech recognition',
          );

          final initialized = await SpeechToTextService.initialize();
          debugPrint('Speech service initialized: $initialized');
          debugPrint(
            'Speech service available: ${SpeechToTextService.isAvailable}',
          );

          if (!initialized && context.mounted) {
            throw Exception(context.t.exceptions.speechRecognitionNotAvailable);
          }
          recognizedText.value = '';
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final filename = 'speaking_recording_$timestamp.aac';

          // Get the app's documents directory for a writable path
          final Directory appDocDir = await getApplicationDocumentsDirectory();
          final String recordingPath = path.join(appDocDir.path, filename);

          await audioRecorder.start(
            const RecordConfig(),
            path: recordingPath,
          );
          isRecording.value = true;
          isListening.value = true;
          await SpeechToTextService.startListening(
            onResult: (final text) {
              recognizedText.value = text;
              debugPrint(
                'Speech recognition update: "$text" (length: ${text.length})',
              );
            },
            listenFor: const Duration(
              seconds: 60,
            ), // Increase to 60 seconds for longer phrases
            pauseFor: const Duration(
              seconds: 2,
            ), // Reduce pause time to 2 seconds for better responsiveness
          );

          debugPrint('Speech recognition started successfully');
          if (context.mounted) {
            ToastService.info(
              context: context,
              message: context.t.speaking.recordingStarted,
            );
          }
        } else {
          debugPrint('Audio recording permission denied');
          if (context.mounted) {
            ToastService.error(
              context: context,
              message: context.t.speaking.audioRecordingPermissionRequired,
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
        await SpeechToTextService.stopListening();
        isRecording.value = false;
        isListening.value = false;
        isProcessing.value = true;

        final userSpeech = recognizedText.value.trim();

        // Debug logging
        debugPrint('Recording stopped. Path: $path');
        debugPrint('Recognized text: "$userSpeech"');
        debugPrint('Text length: ${userSpeech.length}');

        if (userSpeech.isEmpty) {
          if (context.mounted) {
            // Give the user an option to continue without speech recognition
            ToastService.info(
              context: context,
              message: context.t.speaking.noSpeechDetectedCanStillPractice,
            );

            // Add a placeholder message for the conversation
            _addUserMessage(
              conversation,
              context.t.speaking.audioRecordingSpeechNotRecognized,
              path,
            );

            // Save turn to backend if session exists
            if (currentSessionId.value != null) {
              await _saveSpeakingTurn(
                ref,
                currentSessionId.value!,
                context.t.speaking.speakerTypeUser,
                context.t.speaking.audioRecording,
                path ?? '',
              );
            }

            // Generate a helpful AI response
            if (context.mounted) {
              final aiResponse = await aiResponseService
                  .generateSpeakingResponse(
                    userMessage: context
                        .t
                        .speaking
                        .userMadeRecordingButSpeechNotRecognized,
                    conversationContext: conversation.value
                        .where((final m) => !m.isUser)
                        .map((final m) => m.text)
                        .join('\n'),
                  );
              _addAIMessage(conversation, aiResponse);

              // Save AI turn to backend if session exists
              if (currentSessionId.value != null && context.mounted) {
                await _saveSpeakingTurn(
                  ref,
                  currentSessionId.value!,
                  context.t.speaking.speakerTypeAi,
                  aiResponse,
                  '',
                );
              } // Speak AI response
              await TTSService.speak(text: aiResponse);
            }
            isProcessing.value = false;
            return;
          }
        }

        // Add user message to conversation
        _addUserMessage(conversation, userSpeech, path);

        // Save turn to backend if session exists
        if (currentSessionId.value != null && context.mounted) {
          await _saveSpeakingTurn(
            ref,
            currentSessionId.value!,
            context.t.speaking.speakerTypeUser,
            userSpeech,
            path ?? '',
          );
        }

        // Generate AI response from backend
        final aiResponse = await aiResponseService.generateSpeakingResponse(
          userMessage: userSpeech,
          conversationContext: conversation.value
              .where((final m) => !m.isUser)
              .map((final m) => m.text)
              .join('\n'),
        );
        _addAIMessage(conversation, aiResponse);

        // Save AI turn to backend if session exists
        if (currentSessionId.value != null && context.mounted) {
          await _saveSpeakingTurn(
            ref,
            currentSessionId.value!,
            context.t.speaking.speakerTypeAi,
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
      } catch (e) {
        debugPrint('Error in stopRecording: $e');
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
            SessionInfoCard(
              sessionTopic: sessionTopic.value,
              isNewSession: isNewSession,
              currentSessionId: currentSessionId.value,
              onCreateSession: createNewSession,
            ),
            // Conversation Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: conversation.value.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Symbols.chat,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.t.speaking.waitingForConversation,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(
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
                          return ConversationBubble(
                            message: message,
                            onPlayAudio: () {
                              if (message.isUser && message.audioPath != null) {
                                ToastService.info(
                                  context: context,
                                  message: context.t.speaking.recordingPlayed,
                                );
                              } else if (!message.isUser) {
                                TTSService.speak(text: message.text);
                              }
                            },
                          );
                        },
                      ),
              ),
            ),
            // Recording Controls
            RecordingControls(
              isRecording: isRecording.value,
              isProcessing: isProcessing.value,
              onStartRecording: startRecording,
              onStopRecording: stopRecording,
            ),
            if (isListening.value || recognizedText.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  recognizedText.value.isNotEmpty
                      ? recognizedText.value
                      : context.t.speaking.listening,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
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
          aiScore: 0, // Real evaluation can be added here
        ),
      );
      await createTurnUseCase(request);
    } catch (e) {
      debugPrint('Failed to save speaking turn: $e');
    }
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('sessionId', sessionId));
  }
}
