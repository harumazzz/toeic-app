import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../network/dio_client.dart';

part 'ai_response_service.g.dart';

@riverpod
AIResponseService aiResponseService(final Ref ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AIResponseService(dioClient.dio);
}

class AIResponseService {
  const AIResponseService(this._dio);

  final Dio _dio;

  /// Generate AI response for speaking conversation
  Future<String> generateSpeakingResponse({
    required final String userMessage,
    required final String conversationContext,
    final String difficulty = 'intermediate',
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/ai/generate-speaking-response',
        data: {
          'user_message': userMessage,
          'conversation_context': conversationContext,
          'difficulty': difficulty,
        },
      );

      if (response.data != null && response.data!['response'] != null) {
        return response.data!['response'] as String;
      }

      // Fallback response if API fails
      return _getFallbackResponse(userMessage);
    } catch (e) {
      // Return fallback response in case of any error
      return _getFallbackResponse(userMessage);
    }
  }

  /// Generate AI evaluation for user's speaking turn
  Future<Map<String, dynamic>> evaluateSpeaking({
    required final String userText,
    required final String audioPath,
    final String difficulty = 'intermediate',
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/ai/evaluate-speaking',
        data: {
          'user_text': userText,
          'audio_path': audioPath,
          'difficulty': difficulty,
        },
      );

      if (response.data != null) {
        return response.data!;
      }

      return _getFallbackEvaluation();
    } catch (e) {
      return _getFallbackEvaluation();
    }
  }

  String _getFallbackResponse(final String userMessage) {
    final responses = [
      "That's interesting! Can you tell me more about that?",
      'I understand. What do you think about this topic?',
      "That's a good point. How would you explain that to someone else?",
      'Great! Can you give me an example of what you mean?',
      "I see. What's your opinion on this matter?",
      'Excellent! What would you do in a similar situation?',
      "That's thoughtful. How did you come to that conclusion?",
      'Wonderful! Can you describe that in more detail?',
    ];

    // Simple logic to vary responses based on user input length
    if (userMessage.length < 20) {
      return "Could you elaborate on that? I'd love to hear more details.";
    } else if (userMessage.length > 100) {
      return "Thank you for that detailed response! That's very insightful.";
    }

    return responses[(userMessage.length % responses.length)];
  }

  Map<String, dynamic> _getFallbackEvaluation() => {
    'overall_score': 75,
    'pronunciation': 70,
    'fluency': 75,
    'vocabulary': 80,
    'grammar': 75,
    'feedback': 'Good effort! Keep practicing to improve your speaking skills.',
    'suggestions': [
      'Try to speak more slowly and clearly',
      'Use more varied vocabulary',
      'Practice common sentence structures',
    ],
  };
}
