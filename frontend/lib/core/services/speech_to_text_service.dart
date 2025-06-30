import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechToTextService {
  const SpeechToTextService._();

  static final SpeechToText _speechToText = SpeechToText();
  static bool _isInitialized = false;
  static bool _isListening = false;

  static Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      return _isInitialized = await _speechToText.initialize(
        onError: (final error) {
          debugPrint('Speech to text error: $error');
        },
        onStatus: (final status) {
          debugPrint('Speech to text status: $status');
          _isListening = status == 'listening';
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize speech to text: $e');
      return false;
    }
  }

  static bool get isAvailable => _isInitialized && _speechToText.isAvailable;

  static bool get isListening => _isListening;

  static Future<bool> hasPermission() async => _speechToText.hasPermission;

  static Future<void> startListening({
    required final ValueChanged<String> onResult,
    final String localeId = 'en_US',
    final Duration? listenFor,
    final Duration? pauseFor,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('Speech to text not available');
      }
    }

    if (!_speechToText.isAvailable) {
      throw Exception('Speech to text not available');
    }

    await _speechToText.listen(
      onResult: (final result) {
        onResult(result.recognizedWords);
      },
      localeId: localeId,
      listenFor: listenFor,
      pauseFor: pauseFor,
      onSoundLevelChange: (final level) {
        // You can use this for audio level visualization if needed
      },
    );
  }

  /// Stop listening
  static Future<void> stopListening() async {
    if (_isInitialized) {
      await _speechToText.stop();
    }
  }

  /// Cancel listening
  static Future<void> cancelListening() async {
    if (_isInitialized) {
      await _speechToText.cancel();
    }
  }

  /// Get available locales
  static Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speechToText.locales();
  }

  /// Dispose the service
  static Future<void> dispose() async {
    if (_isInitialized) {
      await _speechToText.cancel();
      _isInitialized = false;
      _isListening = false;
    }
  }
}
