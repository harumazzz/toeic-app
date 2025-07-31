import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';

import '../../../../core/services/ai_examiner_service.dart';
import '../../../../core/services/speech_to_text_service.dart';
import '../../../../i18n/strings.g.dart';
import '../../../vocabulary/practice_button.dart';
import '../widgets/evaluation_list.dart';
import '../widgets/evaluation_section.dart';

class ToeicPracticeScreen extends HookWidget {
  const ToeicPracticeScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    final flutterTts = useState<FlutterTts?>(null);
    final audioRecorder = useState<AudioRecorder?>(null);
    final isListening = useState<bool>(false);
    final showImage = useState<bool>(false);
    final showPart5Question = useState<bool>(false);
    final imageKey = useState<int>(DateTime.now().millisecondsSinceEpoch);
    final recognizedText = useState<String>('');
    final lastResponse = useState<String>('');

    // AI Examiner states
    final enableAiExaminer = useState<bool>(false);
    final isAiEvaluating = useState<bool>(false);
    final aiEvaluation = useState<Map<String, dynamic>?>(null);
    final aiQuestion = useState<String>('');
    final currentPart = useState<String>('');
    final currentQuestionData = useState<Map<String, String>?>(null);

    // Initialize TTS and Speech Recognition
    useEffect(() {
      _initializeTts(flutterTts);
      _initializeRecorder(audioRecorder);
      _initializeAI();
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.speaking.toeicPractice.title),
        centerTitle: true,
        actions: [
          // AI Examiner Toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.smart_toy,
                  size: 20,
                  color: enableAiExaminer.value
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                const SizedBox(width: 4),
                Switch.adaptive(
                  value: enableAiExaminer.value,
                  onChanged: (final value) {
                    enableAiExaminer.value = value;
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image for Part 1
            if (showImage.value)
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://picsum.photos/800/600?random=${imageKey.value}',
                      fit: BoxFit.cover,
                      loadingBuilder:
                          (final context, final child, final loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                      errorBuilder:
                          (final context, final error, final stackTrace) =>
                              const Center(
                                child: Icon(
                                  Icons.error,
                                  size: 50,
                                  color: Colors.red,
                                ),
                              ),
                    ),
                  ),
                ),
              ),
            if (showPart5Question.value)
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      context.t.speaking.toeicPractice.part5Question,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

            // Listening indicator and recognized text
            if (isListening.value || recognizedText.value.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isListening.value
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isListening.value
                        ? Colors.red.shade200
                        : Colors.green.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isListening.value
                                  ? Icons.mic
                                  : Icons.check_circle,
                              color: isListening.value
                                  ? Colors.red
                                  : Colors.green,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isListening.value
                                  ? context.t.speaking.toeicPractice.listening
                                  : context.t.speaking.toeicPractice.recognized,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isListening.value
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        if (isListening.value)
                          TextButton.icon(
                            onPressed: () async {
                              await SpeechToTextService.stopListening();
                              isListening.value = false;
                            },
                            icon: const Icon(Icons.stop, size: 16),
                            label: Text(context.t.speaking.toeicPractice.stop),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (recognizedText.value.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        recognizedText.value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Last response display
            if (lastResponse.value.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.chat,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.t.speaking.toeicPractice.yourResponse,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lastResponse.value,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),

            // AI Question Display
            if (aiQuestion.value.isNotEmpty && enableAiExaminer.value)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.smart_toy,
                          color: Colors.purple.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.t.speaking.toeicPractice.aiQuestion,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.purple.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      aiQuestion.value,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),

            // AI Evaluation Display
            if (isAiEvaluating.value)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.orange.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.t.speaking.toeicPractice.aiEvaluating,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ),

            // AI Evaluation Results
            if (aiEvaluation.value != null && enableAiExaminer.value)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.assessment,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.t.speaking.toeicPractice.aiEvaluation,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${context.t.speaking.toeicPractice.score}: ${aiEvaluation.value!['score']}/5',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    EvaluationSection(
                      title: context.t.speaking.toeicPractice.feedback,
                      content: (aiEvaluation.value!['feedback'] ?? '')
                          .toString(),
                      icon: Icons.feedback,
                    ),
                    if (aiEvaluation.value!['strengths'] != null &&
                        aiEvaluation.value!['strengths']
                            .toString()
                            .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      EvaluationSection(
                        title: context.t.speaking.toeicPractice.strengths,
                        content: (aiEvaluation.value!['strengths'] ?? '')
                            .toString(),
                        icon: Icons.thumb_up,
                      ),
                    ],
                    if (aiEvaluation.value!['improvements'] != null &&
                        aiEvaluation.value!['improvements']
                            .toString()
                            .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      EvaluationSection(
                        title: context.t.speaking.toeicPractice.improvements,
                        content: (aiEvaluation.value!['improvements'] ?? '')
                            .toString(),
                        icon: Icons.trending_up,
                      ),
                    ],
                    if (aiEvaluation.value!['grammar_errors'] != null &&
                        (aiEvaluation.value!['grammar_errors'] as List)
                            .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      EvaluationList(
                        title: context.t.speaking.toeicPractice.grammarErrors,
                        items:
                            (aiEvaluation.value!['grammar_errors']
                                    as List<dynamic>)
                                .map((final e) => e.toString())
                                .toList(),
                        icon: Icons.error_outline,
                        color: Colors.red.shade600,
                      ),
                    ],
                    if (aiEvaluation.value!['vocabulary_suggestions'] != null &&
                        (aiEvaluation.value!['vocabulary_suggestions'] as List)
                            .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      EvaluationList(
                        title: context
                            .t
                            .speaking
                            .toeicPractice
                            .vocabularySuggestions,
                        items:
                            (aiEvaluation.value!['vocabulary_suggestions']
                                    as List<dynamic>)
                                .map((final e) => e.toString())
                                .toList(),
                        icon: Icons.lightbulb_outline,
                        color: Colors.amber.shade600,
                      ),
                    ],
                  ],
                ),
              ),

            // Buttons
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Clear results button
                  if (lastResponse.value.isNotEmpty ||
                      recognizedText.value.isNotEmpty ||
                      aiEvaluation.value != null ||
                      aiQuestion.value.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          lastResponse.value = '';
                          recognizedText.value = '';
                          showImage.value = false;
                          showPart5Question.value = false;
                          aiEvaluation.value = null;
                          aiQuestion.value = '';
                          currentPart.value = '';
                          currentQuestionData.value = null;
                        },
                        icon: const Icon(Icons.clear_all, size: 20),
                        label: Text(
                          context.t.speaking.toeicPractice.clearResults,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  PracticeButton(
                    title: context.t.speaking.toeicPractice.part1Title,
                    icon: Icons.image,
                    color: Colors.blue,
                    onPressed: () => _startToeicPart1(
                      context,
                      flutterTts.value,
                      audioRecorder.value,
                      isListening,
                      showImage,
                      showPart5Question,
                      imageKey,
                      recognizedText,
                      lastResponse,
                      enableAiExaminer,
                      isAiEvaluating,
                      aiEvaluation,
                      aiQuestion,
                      currentPart,
                      currentQuestionData,
                    ),
                  ),
                  PracticeButton(
                    title: context.t.speaking.toeicPractice.part2Title,
                    icon: Icons.question_answer,
                    color: Colors.green,
                    onPressed: () => _startToeicPart2(
                      context,
                      flutterTts.value,
                      audioRecorder.value,
                      isListening,
                      showImage,
                      showPart5Question,
                      recognizedText,
                      lastResponse,
                      enableAiExaminer,
                      isAiEvaluating,
                      aiEvaluation,
                      aiQuestion,
                      currentPart,
                      currentQuestionData,
                    ),
                  ),
                  PracticeButton(
                    title: context.t.speaking.toeicPractice.part5Title,
                    icon: Icons.quiz,
                    color: Colors.orange,
                    onPressed: () => _startToeicPart5(
                      context,
                      flutterTts.value,
                      audioRecorder.value,
                      isListening,
                      showImage,
                      showPart5Question,
                      recognizedText,
                      lastResponse,
                      enableAiExaminer,
                      isAiEvaluating,
                      aiEvaluation,
                      aiQuestion,
                      currentPart,
                      currentQuestionData,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Initialize Text-to-Speech
  Future<void> _initializeTts(
    final ValueNotifier<FlutterTts?> flutterTts,
  ) async {
    flutterTts.value = FlutterTts();
    await flutterTts.value?.setLanguage('vi-VN');
    await flutterTts.value?.setSpeechRate(0.8);
    await flutterTts.value?.setVolume(1);
    await flutterTts.value?.setPitch(1);
  }

  // Initialize Audio Recorder and Speech Recognition
  Future<void> _initializeRecorder(
    final ValueNotifier<AudioRecorder?> audioRecorder,
  ) async {
    audioRecorder.value = AudioRecorder();
    // Initialize speech to text service
    await SpeechToTextService.initialize();
  }

  // Speak function
  Future<void> speak(final FlutterTts? tts, final String text) async {
    if (tts != null) {
      await tts.speak(text);
    }
  }

  // Listen function - Using SpeechToTextService
  Future<String> listen(
    final BuildContext context,
    final AudioRecorder? recorder,
    final ValueNotifier<bool> isListening,
    final ValueNotifier<String> recognizedText,
  ) async {
    if (recorder == null) {
      return '';
    }

    try {
      // Check permissions for both recording and speech recognition
      if (await recorder.hasPermission() &&
          await SpeechToTextService.hasPermission()) {
        // Initialize speech to text if needed
        final initialized = await SpeechToTextService.initialize();
        if (!initialized && context.mounted) {
          throw Exception(
            context.t.speaking.toeicPractice.speechRecognitionNotAvailable,
          );
        }

        recognizedText.value = '';
        isListening.value = true;

        // Start recording audio
        await recorder.start(const RecordConfig(), path: 'audio_record.wav');

        // Start speech recognition
        await SpeechToTextService.startListening(
          onResult: (final text) {
            recognizedText.value = text;
          },
          listenFor: const Duration(seconds: 10), // Listen for up to 10 seconds
          pauseFor: const Duration(seconds: 3), // Stop if pause is 3 seconds
        );

        // Wait for listening to complete (either by timeout or manual stop)
        await Future.delayed(const Duration(seconds: 10));

        // Stop recording and speech recognition
        await recorder.stop();
        await SpeechToTextService.stopListening();
        isListening.value = false;

        if (context.mounted) {
          return recognizedText.value.isNotEmpty
              ? recognizedText.value
              : context.t.speaking.toeicPractice.noSpeechDetected;
        }
        return recognizedText.value.isNotEmpty
            ? recognizedText.value
            : 'No speech detected';
      } else {
        if (context.mounted) {
          throw Exception(context.t.speaking.toeicPractice.permissionDenied);
        } else {
          throw Exception(
            'Permission denied for recording or speech recognition',
          );
        }
      }
    } catch (e) {
      isListening.value = false;
      debugPrint('Error during speech recognition: $e');
      return 'Error: $e';
    }
  }

  // Initialize AI Examiner
  Future<void> _initializeAI() async {
    await AIExaminerService.initialize();
  }

  // Evaluate user response with AI
  Future<void> _evaluateWithAI({
    required final BuildContext context,
    required final String userResponse,
    required final String partType,
    required final String question,
    required final ValueNotifier<bool> isAiEvaluating,
    required final ValueNotifier<Map<String, dynamic>?> aiEvaluation,
    required final ValueNotifier<String> aiQuestion,
    final Map<String, String>? questionData,
  }) async {
    if (!AIExaminerService.isInitialized) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t.speaking.toeicPractice.aiNotAvailable),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    isAiEvaluating.value = true;
    aiEvaluation.value = null;

    try {
      Map<String, dynamic> evaluation;

      switch (partType) {
        case 'Part1':
          evaluation = await AIExaminerService.evaluatePart1Response(
            userResponse: userResponse,
            question: question,
          );
          break;
        case 'Part2':
          evaluation = await AIExaminerService.evaluatePart2Response(
            userResponse: userResponse,
            question: question,
          );
          break;
        case 'Part5':
          evaluation = await AIExaminerService.evaluatePart5Response(
            userResponse: userResponse,
            questionData: questionData!,
          );
          break;
        default:
          evaluation = {'score': 0, 'feedback': 'Unknown part type'};
      }

      aiEvaluation.value = evaluation;

      // Generate follow-up question
      final followUp = await AIExaminerService.generateFollowUpQuestion(
        userResponse: userResponse,
        originalQuestion: question,
        partType: partType,
      );
      aiQuestion.value = followUp;
    } catch (e) {
      debugPrint('AI Evaluation Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.t.speaking.toeicPractice.aiError}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isAiEvaluating.value = false;
    }
  }

  // Part 1 Function - Updated with AI support
  Future<void> _startToeicPart1(
    final BuildContext context,
    final FlutterTts? tts,
    final AudioRecorder? recorder,
    final ValueNotifier<bool> isListening,
    final ValueNotifier<bool> showImage,
    final ValueNotifier<bool> showPart5Question,
    final ValueNotifier<int> imageKey,
    final ValueNotifier<String> recognizedText,
    final ValueNotifier<String> lastResponse,
    final ValueNotifier<bool> enableAiExaminer,
    final ValueNotifier<bool> isAiEvaluating,
    final ValueNotifier<Map<String, dynamic>?> aiEvaluation,
    final ValueNotifier<String> aiQuestion,
    final ValueNotifier<String> currentPart,
    final ValueNotifier<Map<String, String>?> currentQuestionData,
  ) async {
    // Hide other UI elements
    showPart5Question.value = false;
    aiEvaluation.value = null;
    aiQuestion.value = '';

    // Set current part
    currentPart.value = 'Part1';

    // Generate new random image
    imageKey.value = DateTime.now().millisecondsSinceEpoch;

    // Show image
    showImage.value = true;

    // Wait a bit for image to load
    await Future.delayed(const Duration(seconds: 2));

    // Get AI question or use default
    String question;
    if (enableAiExaminer.value) {
      question = AIExaminerService.getRandomPart1Question();
      aiQuestion.value = question;
      await speak(tts, question);
    } else {
      if (context.mounted) {
        question = context.t.speaking.toeicPractice.part1Instruction;
        await speak(tts, question);

        // Wait for speech to finish
        await Future.delayed(const Duration(seconds: 2));

        // Listen to user response
        if (context.mounted) {
          final userResponse = await listen(
            context,
            recorder,
            isListening,
            recognizedText,
          );
          lastResponse.value = userResponse;

          // Evaluate with AI if enabled
          if (enableAiExaminer.value &&
              userResponse.isNotEmpty &&
              context.mounted &&
              !userResponse.startsWith('Error:') &&
              userResponse !=
                  context.t.speaking.toeicPractice.noSpeechDetected) {
            if (context.mounted) {
              await _evaluateWithAI(
                context: context,
                userResponse: userResponse,
                partType: 'Part1',
                question: question,
                isAiEvaluating: isAiEvaluating,
                aiEvaluation: aiEvaluation,
                aiQuestion: aiQuestion,
              );
            }
          }

          debugPrint('Part 1 - User description: $userResponse');
        }
      }
    }
  }

  // Part 2 Function - Updated with AI support
  Future<void> _startToeicPart2(
    final BuildContext context,
    final FlutterTts? tts,
    final AudioRecorder? recorder,
    final ValueNotifier<bool> isListening,
    final ValueNotifier<bool> showImage,
    final ValueNotifier<bool> showPart5Question,
    final ValueNotifier<String> recognizedText,
    final ValueNotifier<String> lastResponse,
    final ValueNotifier<bool> enableAiExaminer,
    final ValueNotifier<bool> isAiEvaluating,
    final ValueNotifier<Map<String, dynamic>?> aiEvaluation,
    final ValueNotifier<String> aiQuestion,
    final ValueNotifier<String> currentPart,
    final ValueNotifier<Map<String, String>?> currentQuestionData,
  ) async {
    // Hide other UI elements
    showImage.value = false;
    showPart5Question.value = false;
    aiEvaluation.value = null;
    aiQuestion.value = '';

    // Set current part
    currentPart.value = 'Part2';

    // Get AI question or use default
    String question;
    if (enableAiExaminer.value) {
      question = AIExaminerService.getRandomPart2Question();
      aiQuestion.value = question;
      await speak(tts, question);
    } else {
      question = context.t.speaking.toeicPractice.part2Instruction;
      await speak(tts, question);
    }

    // Wait for speech to finish
    await Future.delayed(const Duration(seconds: 2));

    // Listen to user response
    if (context.mounted) {
      final userResponse = await listen(
        context,
        recorder,
        isListening,
        recognizedText,
      );
      lastResponse.value = userResponse;

      // Evaluate with AI if enabled
      if (enableAiExaminer.value &&
          userResponse.isNotEmpty &&
          !userResponse.startsWith('Error:') &&
          context.mounted &&
          userResponse != context.t.speaking.toeicPractice.noSpeechDetected) {
        await _evaluateWithAI(
          context: context,
          userResponse: userResponse,
          partType: 'Part2',
          question: question,
          isAiEvaluating: isAiEvaluating,
          aiEvaluation: aiEvaluation,
          aiQuestion: aiQuestion,
        );
      }

      debugPrint('Part 2 - User answer: $userResponse');
    }
  }

  // Part 5 Function - Updated with AI support
  Future<void> _startToeicPart5(
    final BuildContext context,
    final FlutterTts? tts,
    final AudioRecorder? recorder,
    final ValueNotifier<bool> isListening,
    final ValueNotifier<bool> showImage,
    final ValueNotifier<bool> showPart5Question,
    final ValueNotifier<String> recognizedText,
    final ValueNotifier<String> lastResponse,
    final ValueNotifier<bool> enableAiExaminer,
    final ValueNotifier<bool> isAiEvaluating,
    final ValueNotifier<Map<String, dynamic>?> aiEvaluation,
    final ValueNotifier<String> aiQuestion,
    final ValueNotifier<String> currentPart,
    final ValueNotifier<Map<String, String>?> currentQuestionData,
  ) async {
    // Hide other UI elements
    showImage.value = false;
    aiEvaluation.value = null;
    aiQuestion.value = '';

    // Set current part
    currentPart.value = 'Part5';

    // Get AI question or use default
    Map<String, String> questionData;
    String instruction;

    if (enableAiExaminer.value) {
      questionData = AIExaminerService.getRandomPart5Question();
      currentQuestionData.value = questionData;
      instruction =
          "Please choose the correct answer for this grammar question and explain your choice: ${questionData['question']} Options: ${questionData['options']}";
      aiQuestion.value = instruction;
    } else {
      questionData = {
        'question': context.t.speaking.toeicPractice.part5Question,
        'options':
            '(A) supervise (B) supervising (C) supervision (D) supervised',
        'correct': 'B',
        'explanation': 'Use gerund "supervising" after "for".',
      };
      currentQuestionData.value = questionData;
      instruction = context.t.speaking.toeicPractice.part5Instruction;
    }

    // Show Part 5 question
    showPart5Question.value = true;

    // Speak instruction and question
    await speak(tts, instruction);

    // Wait for speech to finish
    await Future.delayed(const Duration(seconds: 2));

    // Listen to user response
    if (context.mounted) {
      final userResponse = await listen(
        context,
        recorder,
        isListening,
        recognizedText,
      );
      lastResponse.value = userResponse;

      // Evaluate with AI if enabled
      if (enableAiExaminer.value &&
          userResponse.isNotEmpty &&
          !userResponse.startsWith('Error:') &&
          context.mounted &&
          userResponse != context.t.speaking.toeicPractice.noSpeechDetected) {
        if (context.mounted) {
          await _evaluateWithAI(
            context: context,
            userResponse: userResponse,
            partType: 'Part5',
            question: instruction,
            isAiEvaluating: isAiEvaluating,
            aiEvaluation: aiEvaluation,
            aiQuestion: aiQuestion,
            questionData: questionData,
          );
        }
      }

      // debugPrint result
      debugPrint('Part 5 - User answer and explanation: $userResponse');
    }
  }
}
