import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../i18n/strings.g.dart';
import '../models/toeic_evaluation.dart';

/// AI Examiner Service using Firebase Gemini AI to act as TOEIC examiner
/// This service leverages Firebase's Generative AI with advanced Gemini models
/// for comprehensive TOEIC speaking practice and evaluation.
class AIExaminerService {
  static GenerativeModel? _model;
  static GenerativeModel? _advancedModel;
  static bool _isInitialized = false;

  // TOEIC questions bank for different parts
  static List<String> get _part1Questions => [
    t.speaking.toeicPractice.aiService.questions.part1.describeDetail,
    t.speaking.toeicPractice.aiService.questions.part1.describePeople,
    t.speaking.toeicPractice.aiService.questions.part1.describeScene,
    t.speaking.toeicPractice.aiService.questions.part1.describeSetting,
    t.speaking.toeicPractice.aiService.questions.part1.identifyObjects,
  ];

  static List<String> get _part2Questions => [
    t.speaking.toeicPractice.aiService.questions.part2.lastWeekend,
    t.speaking.toeicPractice.aiService.questions.part2.idealVacation,
    t.speaking.toeicPractice.aiService.questions.part2.favoriteHobby,
    t.speaking.toeicPractice.aiService.questions.part2.hometown,
    t.speaking.toeicPractice.aiService.questions.part2.futurePlans,
    t.speaking.toeicPractice.aiService.questions.part2.memorableExperience,
    t.speaking.toeicPractice.aiService.questions.part2.favoriteMusic,
    t.speaking.toeicPractice.aiService.questions.part2.favoriteRestaurant,
    t.speaking.toeicPractice.aiService.questions.part2.freeTime,
    t.speaking.toeicPractice.aiService.questions.part2.bestFriend,
  ];

  static List<ToeicPart5Question> get _part5Questions => [
    ToeicPart5Question(
      question: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .meetingPostponed
          .question,
      options: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .meetingPostponed
          .options,
      correct: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .meetingPostponed
          .correct,
      explanation: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .meetingPostponed
          .explanation,
    ),
    ToeicPart5Question(
      question: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .workingYears
          .question,
      options: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .workingYears
          .options,
      correct: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .workingYears
          .correct,
      explanation: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .workingYears
          .explanation,
    ),
    ToeicPart5Question(
      question: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .reportCompleted
          .question,
      options: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .reportCompleted
          .options,
      correct: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .reportCompleted
          .correct,
      explanation: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .reportCompleted
          .explanation,
    ),
    ToeicPart5Question(
      question: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .achieveTargets
          .question,
      options: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .achieveTargets
          .options,
      correct: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .achieveTargets
          .correct,
      explanation: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .achieveTargets
          .explanation,
    ),
    ToeicPart5Question(
      question: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .weatherImproves
          .question,
      options: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .weatherImproves
          .options,
      correct: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .weatherImproves
          .correct,
      explanation: t
          .speaking
          .toeicPractice
          .aiService
          .questions
          .part5
          .weatherImproves
          .explanation,
    ),
  ];

  /// Initialize Firebase AI with enhanced Gemini models
  /// Uses Gemini-1.5-flash for quick responses and Gemini-1.5-pro
  static Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Initialize primary model (Gemini 1.5 Flash) for quick responses
      _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.9,
          maxOutputTokens: 1024,
        ),
      );

      // Initialize advanced model (Gemini 1.5 Pro) for complex evaluations
      _advancedModel = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-pro',
        generationConfig: GenerationConfig(
          temperature: 0.3, // Lower temperature for more consistent evaluations
          topK: 20,
          topP: 0.8,
          maxOutputTokens: 2048,
        ),
      );

      _isInitialized = true;
      debugPrint(t.speaking.toeicPractice.aiService.initSuccess);
      debugPrint(t.speaking.toeicPractice.aiService.initPrimaryModel);
      debugPrint(t.speaking.toeicPractice.aiService.initAdvancedModel);
      return true;
    } catch (e) {
      debugPrint('${t.speaking.toeicPractice.aiService.initFailed}: $e');
      return false;
    }
  }

  /// Get a random Part 1 question (image description)
  static String getRandomPart1Question() {
    final random = Random();
    return _part1Questions[random.nextInt(_part1Questions.length)];
  }

  /// Get a random Part 2 question (Q&A)
  static String getRandomPart2Question() {
    final random = Random();
    return _part2Questions[random.nextInt(_part2Questions.length)];
  }

  /// Get a random Part 5 question (grammar)
  static ToeicPart5Question getRandomPart5Question() {
    final random = Random();
    return _part5Questions[random.nextInt(_part5Questions.length)];
  }

  /// Evaluate Part 1 response (image description) with advanced Gemini Pro
  static Future<ToeicEvaluation> evaluatePart1Response({
    required final String userResponse,
    required final String question,
  }) async {
    if (!_isInitialized || _advancedModel == null) {
      await initialize();
    }

    try {
      final prompt = t.speaking.toeicPractice.aiService.prompts.part1Evaluation
          .replaceAll('{question}', question)
          .replaceAll('{userResponse}', userResponse);

      final content = [Content.text(prompt)];
      final response = await _advancedModel!.generateContent(content);

      if (response.text != null) {
        final jsonString = _extractJsonFromResponse(response.text!);
        final result = jsonDecode(jsonString) as Map<String, dynamic>;
        debugPrint(t.speaking.toeicPractice.aiService.part1EvaluationComplete);
        return ToeicEvaluation.fromJson(result);
      }

      return _getDefaultEvaluation();
    } catch (e) {
      debugPrint(
        '${t.speaking.toeicPractice.aiService.part1EvaluationError}: $e',
      );
      return _getDefaultEvaluation();
    }
  }

  /// Evaluate Part 2 response (Q&A) with advanced Gemini Pro
  static Future<ToeicEvaluation> evaluatePart2Response({
    required final String userResponse,
    required final String question,
  }) async {
    if (!_isInitialized || _advancedModel == null) {
      await initialize();
    }

    try {
      final prompt = t.speaking.toeicPractice.aiService.prompts.part2Evaluation
          .replaceAll('{question}', question)
          .replaceAll('{userResponse}', userResponse);

      final content = [Content.text(prompt)];
      final response = await _advancedModel!.generateContent(content);

      if (response.text != null) {
        final jsonString = _extractJsonFromResponse(response.text!);
        final result = jsonDecode(jsonString) as Map<String, dynamic>;
        debugPrint(t.speaking.toeicPractice.aiService.part2EvaluationComplete);
        return ToeicEvaluation.fromJson(result);
      }

      return _getDefaultEvaluation();
    } catch (e) {
      debugPrint(
        '${t.speaking.toeicPractice.aiService.part2EvaluationError}: $e',
      );
      return _getDefaultEvaluation();
    }
  }

  /// Evaluate Part 5 response (grammar explanation) with advanced Gemini Pro
  static Future<ToeicEvaluation> evaluatePart5Response({
    required final String userResponse,
    required final ToeicPart5Question questionData,
  }) async {
    if (!_isInitialized || _advancedModel == null) {
      await initialize();
    }

    try {
      final prompt = t.speaking.toeicPractice.aiService.prompts.part5Evaluation
          .replaceAll('{question}', questionData.question)
          .replaceAll('{options}', questionData.options)
          .replaceAll('{correct}', questionData.correct)
          .replaceAll('{explanation}', questionData.explanation)
          .replaceAll('{userResponse}', userResponse);

      final content = [Content.text(prompt)];
      final response = await _advancedModel!.generateContent(content);

      if (response.text != null) {
        final jsonString = _extractJsonFromResponse(response.text!);
        final result = jsonDecode(jsonString) as Map<String, dynamic>;
        debugPrint(t.speaking.toeicPractice.aiService.part5EvaluationComplete);
        return ToeicEvaluation.fromJson(result);
      }

      return _getDefaultEvaluation();
    } catch (e) {
      debugPrint(
        '${t.speaking.toeicPractice.aiService.part5EvaluationError}: $e',
      );
      return _getDefaultEvaluation();
    }
  }

  /// Generate intelligent follow-up question using Gemini's advanced reasoning
  static Future<String> generateFollowUpQuestion({
    required final String userResponse,
    required final String originalQuestion,
    required final String partType,
  }) async {
    if (!_isInitialized || _model == null) {
      await initialize();
    }

    try {
      final prompt = t
          .speaking
          .toeicPractice
          .aiService
          .prompts
          .followUpGeneration
          .replaceAll('{partType}', partType)
          .replaceAll('{originalQuestion}', originalQuestion)
          .replaceAll('{userResponse}', userResponse);

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      final followUpQuestion =
          response.text?.trim() ??
          t.speaking.toeicPractice.aiService.prompts.followUpFallback;
      final msg =
          // ignore: lines_longer_than_80_chars
          '${t.speaking.toeicPractice.aiService.followUpGenerated}: $followUpQuestion';
      debugPrint(msg);
      return followUpQuestion;
    } catch (e) {
      debugPrint('${t.speaking.toeicPractice.aiService.followUpError}: $e');
      return t.speaking.toeicPractice.aiService.prompts.followUpFallback;
    }
  }

  /// Generate adaptive TOEIC questions using Gemini's advanced reasoning
  static Future<AdaptiveToeicQuestion> generateAdaptiveToeicQuestion({
    required final String partType,
    required final String difficultyLevel, // beginner, intermediate, advanced
    final String? previousPerformance,
  }) async {
    if (!_isInitialized || _advancedModel == null) {
      await initialize();
    }

    try {
      final prompt = t
          .speaking
          .toeicPractice
          .aiService
          .prompts
          .adaptiveQuestionGeneration
          .replaceAll('{partType}', partType)
          .replaceAll('{difficultyLevel}', difficultyLevel)
          .replaceAll(
            '{previousPerformance}',
            previousPerformance ?? 'No previous data',
          );

      final content = [Content.text(prompt)];
      final response = await _advancedModel!.generateContent(content);

      if (response.text != null) {
        final jsonString = _extractJsonFromResponse(response.text!);
        final result = jsonDecode(jsonString) as Map<String, dynamic>;

        debugPrint(
          // ignore: lines_longer_than_80_chars
          '${t.speaking.toeicPractice.aiService.adaptiveQuestionGenerated} ($partType - $difficultyLevel)',
        );
        return AdaptiveToeicQuestion.fromJson(result);
      }

      // Fallback to existing static questions
      final staticQuestion = getRandomPart5Question();
      return AdaptiveToeicQuestion(
        question: staticQuestion.question,
        topic: 'Grammar',
        difficultyIndicators: ['Static question'],
        learningObjectives: ['Grammar practice'],
        options: staticQuestion.options,
        correct: staticQuestion.correct,
        explanation: staticQuestion.explanation,
      );
    } catch (e) {
      debugPrint(
        '${t.speaking.toeicPractice.aiService.adaptiveQuestionError}: $e',
      );
      // Fallback to existing static questions
      final staticQuestion = getRandomPart5Question();
      return AdaptiveToeicQuestion(
        question: staticQuestion.question,
        topic: 'Grammar',
        difficultyIndicators: ['Static question'],
        learningObjectives: ['Grammar practice'],
        options: staticQuestion.options,
        correct: staticQuestion.correct,
        explanation: staticQuestion.explanation,
      );
    }
  }

  /// Analyze user's progress and recommend personalized study plan
  static Future<StudyPlan> generatePersonalizedStudyPlan({
    required final List<ToeicEvaluation> recentEvaluations,
    required final String targetScore,
  }) async {
    if (!_isInitialized || _advancedModel == null) {
      await initialize();
    }

    try {
      final evaluationsText = recentEvaluations
          .map(
            (final eval) =>
                // ignore: lines_longer_than_80_chars
                'Score: ${eval.score}, Strengths: ${eval.strengths}, Improvements: ${eval.improvements}',
          )
          .join('\n');

      final prompt = t
          .speaking
          .toeicPractice
          .aiService
          .prompts
          .studyPlanGeneration
          .replaceAll('{evaluationsText}', evaluationsText)
          .replaceAll('{targetScore}', targetScore);

      final content = [Content.text(prompt)];
      final response = await _advancedModel!.generateContent(content);

      if (response.text != null) {
        final jsonString = _extractJsonFromResponse(response.text!);
        final result = jsonDecode(jsonString) as Map<String, dynamic>;
        debugPrint(t.speaking.toeicPractice.aiService.studyPlanGenerated);
        return StudyPlan.fromJson(result);
      }

      return _getDefaultStudyPlan();
    } catch (e) {
      debugPrint('${t.speaking.toeicPractice.aiService.studyPlanError}: $e');
      return _getDefaultStudyPlan();
    }
  }

  /// Extract JSON from AI response text with improved parsing
  static String _extractJsonFromResponse(final String response) {
    // Clean the response and find JSON content
    final cleanResponse = response.trim();

    // Try to find JSON block markers first
    final jsonBlockStart = cleanResponse.indexOf('```json');
    if (jsonBlockStart != -1) {
      final jsonStart = cleanResponse.indexOf('{', jsonBlockStart);
      final jsonEnd = cleanResponse.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        return cleanResponse.substring(jsonStart, jsonEnd + 1);
      }
    }

    // Try to find JSON in the response directly
    final jsonStart = cleanResponse.indexOf('{');
    final jsonEnd = cleanResponse.lastIndexOf('}');

    if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
      return cleanResponse.substring(jsonStart, jsonEnd + 1);
    }

    // Return a default JSON structure if parsing fails
    debugPrint(t.speaking.toeicPractice.aiService.jsonExtractionWarning);
    return jsonEncode(_getDefaultEvaluation().toJson());
  }

  /// Get enhanced default evaluation with more comprehensive feedback
  static ToeicEvaluation _getDefaultEvaluation() => ToeicEvaluation(
    score: 3,
    feedback: t.speaking.toeicPractice.aiService.defaultEvaluation.feedback,
    pronunciationScore: 3,
    fluencyScore: 3,
    grammarScore: 3,
    vocabularyScore: 3,
    contentRelevanceScore: 3,
    strengths: t.speaking.toeicPractice.aiService.defaultEvaluation.strengths,
    improvements:
        t.speaking.toeicPractice.aiService.defaultEvaluation.improvements,
    grammarErrors: [],
    vocabularySuggestions: [],
    speakingTips: [
      t
          .speaking
          .toeicPractice
          .aiService
          .defaultEvaluation
          .speakingTips
          .practice,
      t.speaking.toeicPractice.aiService.defaultEvaluation.speakingTips.record,
      t
          .speaking
          .toeicPractice
          .aiService
          .defaultEvaluation
          .speakingTips
          .pronunciation,
    ],
    estimatedToeicLevel:
        t.speaking.toeicPractice.aiService.defaultEvaluation.estimatedLevel,
    confidenceLevel: 75,
  );

  /// Get default study plan for fallback scenarios
  static StudyPlan _getDefaultStudyPlan() => StudyPlan(
    currentLevelAssessment:
        t.speaking.toeicPractice.aiService.defaultStudyPlan.levelAssessment,
    strengths: t.speaking.toeicPractice.aiService.defaultStudyPlan.strengths,
    priorityAreas:
        t.speaking.toeicPractice.aiService.defaultStudyPlan.priorityAreas,
    weeklyPlan: WeeklyStudyPlan(
      week1:
          t.speaking.toeicPractice.aiService.defaultStudyPlan.weeklyPlan.week1,
      week2:
          t.speaking.toeicPractice.aiService.defaultStudyPlan.weeklyPlan.week2,
      week3:
          t.speaking.toeicPractice.aiService.defaultStudyPlan.weeklyPlan.week3,
      week4:
          t.speaking.toeicPractice.aiService.defaultStudyPlan.weeklyPlan.week4,
    ),
    practiceFocus: PracticeFocus(
      grammar: t
          .speaking
          .toeicPractice
          .aiService
          .defaultStudyPlan
          .practiceFocus
          .grammar,
      vocabulary: t
          .speaking
          .toeicPractice
          .aiService
          .defaultStudyPlan
          .practiceFocus
          .vocabulary,
      speaking: t
          .speaking
          .toeicPractice
          .aiService
          .defaultStudyPlan
          .practiceFocus
          .speaking,
      listening: t
          .speaking
          .toeicPractice
          .aiService
          .defaultStudyPlan
          .practiceFocus
          .listening,
    ),
    progressMilestones:
        t.speaking.toeicPractice.aiService.defaultStudyPlan.milestones,
    estimatedTimeline:
        t.speaking.toeicPractice.aiService.defaultStudyPlan.timeline,
    motivationTips:
        t.speaking.toeicPractice.aiService.defaultStudyPlan.motivationTips,
    recommendedResources:
        t.speaking.toeicPractice.aiService.defaultStudyPlan.resources,
  );

  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;

  /// Dispose resources and clean up models
  static void dispose() {
    _model = null;
    _advancedModel = null;
    _isInitialized = false;
    debugPrint(t.speaking.toeicPractice.aiService.serviceDisposed);
  }
}
