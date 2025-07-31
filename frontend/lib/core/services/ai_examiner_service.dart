import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

/// AI Examiner Service using Firebase AI to act as TOEIC examiner
class AIExaminerService {
  static GenerativeModel? _model;
  static bool _isInitialized = false;

  // TOEIC questions bank for different parts
  static final List<String> _part1Questions = [
    'Describe what you see in this image in detail.',
    'Tell me about the people and activities in this picture.',
    'What is happening in this image? Describe the scene.',
    'Describe the setting and atmosphere of this picture.',
    'What objects or elements can you identify in this image?',
  ];

  static final List<String> _part2Questions = [
    'What did you do last weekend?',
    'Describe your ideal vacation destination.',
    'What is your favorite hobby and why?',
    'Tell me about your hometown.',
    'What are your plans for the future?',
    'Describe a memorable experience you had recently.',
    'What type of music do you enjoy and why?',
    'Tell me about your favorite restaurant.',
    'What do you like to do in your free time?',
    'Describe your best friend.',
  ];

  static final List<Map<String, String>> _part5Questions = [
    {
      'question':
          'The meeting _____ postponed until next week due to technical issues.',
      'options': 'A) was B) were C) is D) are',
      'correct': 'A',
      'explanation':
          'Use "was" because "meeting" is singular and the sentence is in past tense.',
    },
    {
      'question': 'She has been working here _____ five years.',
      'options': 'A) since B) for C) during D) from',
      'correct': 'B',
      'explanation': 'Use "for" with a period of time (five years).',
    },
    {
      'question': 'The report must be _____ by Friday.',
      'options': 'A) complete B) completed C) completing D) completion',
      'correct': 'B',
      'explanation':
          'Use past participle "completed" in passive voice construction.',
    },
    {
      'question': 'We need to _____ our sales targets this quarter.',
      'options': 'A) achieve B) achievement C) achieving D) achieved',
      'correct': 'A',
      'explanation': 'Use base form "achieve" after "need to".',
    },
    {
      'question':
          '_____ the weather improves, we will cancel the outdoor event.',
      'options': 'A) If B) Unless C) When D) Because',
      'correct': 'B',
      'explanation':
          'Use "Unless" meaning "if not" - if the weather does not improve.',
    },
  ];

  /// Initialize Firebase AI
  static Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Initialize Firebase Vertex AI with Gemini model
      _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.9,
          maxOutputTokens: 1024,
        ),
      );
      _isInitialized = true;
      debugPrint('AI Examiner Service initialized successfully');
      return true;
    } catch (e) {
      debugPrint('Failed to initialize AI Examiner Service: $e');
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
  static Map<String, String> getRandomPart5Question() {
    final random = Random();
    return _part5Questions[random.nextInt(_part5Questions.length)];
  }

  /// Evaluate Part 1 response (image description)
  static Future<Map<String, dynamic>> evaluatePart1Response({
    required final String userResponse,
    required final String question,
  }) async {
    if (!_isInitialized || _model == null) {
      await initialize();
    }

    try {
      final prompt =
          '''
You are a TOEIC speaking test examiner. Evaluate this Part 1 response (image description).

Question: $question
Student's Response: "$userResponse"

Please provide evaluation in JSON format:
{
  "score": [score from 0-5],
  "feedback": "detailed feedback about grammar, vocabulary, fluency, and content",
  "strengths": "what the student did well",
  "improvements": "specific areas for improvement",
  "grammar_errors": ["list of grammar mistakes if any"],
  "vocabulary_suggestions": ["better word choices if any"]
}

Evaluation criteria:
- Content relevance and accuracy (0-1 points)
- Grammar and sentence structure (0-1 points)  
- Vocabulary usage (0-1 points)
- Fluency and coherence (0-1 points)
- Pronunciation and clarity (0-1 points)

Be encouraging but constructive in your feedback.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      if (response.text != null) {
        // Try to parse JSON from response
        final jsonString = _extractJsonFromResponse(response.text!);
        final result = jsonDecode(jsonString);
        return result as Map<String, dynamic>;
      }

      return _getDefaultEvaluation();
    } catch (e) {
      debugPrint('Error evaluating Part 1 response: $e');
      return _getDefaultEvaluation();
    }
  }

  /// Evaluate Part 2 response (Q&A)
  static Future<Map<String, dynamic>> evaluatePart2Response({
    required final String userResponse,
    required final String question,
  }) async {
    if (!_isInitialized || _model == null) {
      await initialize();
    }

    try {
      final prompt =
          '''
You are a TOEIC speaking test examiner. Evaluate this Part 2 response (question and answer).

Question: $question
Student's Response: "$userResponse"

Please provide evaluation in JSON format:
{
  "score": [score from 0-5],
  "feedback": "detailed feedback about relevance, grammar, vocabulary, and fluency",
  "strengths": "what the student did well",
  "improvements": "specific areas for improvement",
  "grammar_errors": ["list of grammar mistakes if any"],
  "vocabulary_suggestions": ["better word choices if any"]
}

Evaluation criteria:
- Relevance to question (0-1 points)
- Grammar and sentence structure (0-1 points)
- Vocabulary range and accuracy (0-1 points)
- Fluency and coherence (0-1 points)
- Overall communication effectiveness (0-1 points)

Be encouraging but provide specific, actionable feedback.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      if (response.text != null) {
        final jsonString = _extractJsonFromResponse(response.text!);
        final result = jsonDecode(jsonString);
        return result as Map<String, dynamic>;
      }

      return _getDefaultEvaluation();
    } catch (e) {
      debugPrint('Error evaluating Part 2 response: $e');
      return _getDefaultEvaluation();
    }
  }

  /// Evaluate Part 5 response (grammar explanation)
  static Future<Map<String, dynamic>> evaluatePart5Response({
    required final String userResponse,
    required final Map<String, String> questionData,
  }) async {
    if (!_isInitialized || _model == null) {
      await initialize();
    }

    try {
      final prompt =
          '''
You are a TOEIC speaking test examiner. Evaluate this Part 5 response (grammar question explanation).

Question: ${questionData['question']}
Options: ${questionData['options']}
Correct Answer: ${questionData['correct']}
Correct Explanation: ${questionData['explanation']}
Student's Response: "$userResponse"

Please provide evaluation in JSON format:
{
  "score": [score from 0-5],
  "feedback": "detailed feedback about correctness, explanation quality, and language use",
  "strengths": "what the student did well",
  "improvements": "specific areas for improvement",
  "correct_answer": "whether they chose the right answer",
  "explanation_quality": "how well they explained their choice"
}

Evaluation criteria:
- Correct answer selection (0-2 points)
- Quality of explanation (0-2 points)
- Language accuracy and clarity (0-1 points)

Provide constructive feedback focusing on grammar understanding.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      if (response.text != null) {
        final jsonString = _extractJsonFromResponse(response.text!);
        final result = jsonDecode(jsonString);
        return result as Map<String, dynamic>;
      }

      return _getDefaultEvaluation();
    } catch (e) {
      debugPrint('Error evaluating Part 5 response: $e');
      return _getDefaultEvaluation();
    }
  }

  /// Generate follow-up question based on user response
  static Future<String> generateFollowUpQuestion({
    required final String userResponse,
    required final String originalQuestion,
    required final String partType,
  }) async {
    if (!_isInitialized || _model == null) {
      await initialize();
    }

    try {
      final prompt =
          '''
You are a TOEIC speaking examiner. Based on the student's response, generate a relevant follow-up question.

Part Type: $partType
Original Question: $originalQuestion
Student's Response: "$userResponse"

Generate a follow-up question that:
- Is related to their response
- Encourages them to elaborate or clarify
- Maintains appropriate TOEIC difficulty level
- Helps assess their speaking ability further

Respond with just the follow-up question, no additional text.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      return response.text?.trim() ?? 'Can you tell me more about that?';
    } catch (e) {
      debugPrint('Error generating follow-up question: $e');
      return 'Can you tell me more about that?';
    }
  }

  /// Extract JSON from AI response text
  static String _extractJsonFromResponse(final String response) {
    // Try to find JSON block in the response
    final jsonStart = response.indexOf('{');
    final jsonEnd = response.lastIndexOf('}');

    if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
      return response.substring(jsonStart, jsonEnd + 1);
    }

    // Return a default JSON structure if parsing fails
    return jsonEncode(_getDefaultEvaluation());
  }

  /// Get default evaluation when AI fails
  static Map<String, dynamic> _getDefaultEvaluation() => {
    'score': 3,
    'feedback': 'Good effort! Keep practicing to improve your speaking skills.',
    'strengths': 'You attempted to answer the question.',
    'improvements': 'Focus on grammar, vocabulary, and fluency.',
    'grammar_errors': <String>[],
    'vocabulary_suggestions': <String>[],
  };

  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;

  /// Dispose resources
  static void dispose() {
    _model = null;
    _isInitialized = false;
  }
}
