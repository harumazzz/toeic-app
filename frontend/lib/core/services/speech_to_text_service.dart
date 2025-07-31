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
      debugPrint('Speech to text already initialized');
      return true;
    }

    try {
      debugPrint('Initializing speech to text...');

      // Check if speech recognition is available on this device
      final available = await _speechToText.hasPermission;
      if (!available) {
        debugPrint('Speech to text permission not granted');
        return false;
      }

      final result = await _speechToText.initialize(
        onError: (final error) {
          debugPrint('Speech to text error: ${error.errorMsg}');
        },
        onStatus: (final status) {
          debugPrint('Speech to text status: $status');
          _isListening = status == 'listening';
        },
      );
      _isInitialized = result;

      if (result) {
        final locales = await _speechToText.locales();
        debugPrint(
          'Available speech locales: ${locales.map(
            (final l) => l.localeId,
          ).take(5).join(', ')}...',
        );
      }

      debugPrint(
        'Speech to text initialization ${result ? 'successful' : 'failed'}',
      );
      return result;
    } catch (e) {
      debugPrint('Failed to initialize speech to text: $e');
      return false;
    }
  }

  static bool get isAvailable => _isInitialized && _speechToText.isAvailable;

  static bool get isListening => _isListening;

  static Future<bool> hasPermission() async {
    final permission = await _speechToText.hasPermission;
    debugPrint('Speech to text permission status: $permission');
    return permission;
  }

  static Future<bool> requestPermission() async {
    if (!_isInitialized) {
      await initialize();
    }
    final permission = await _speechToText.hasPermission;
    debugPrint('Speech to text permission after request: $permission');
    return permission;
  }

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

    debugPrint('Starting speech recognition with locale: $localeId');
    debugPrint('Listen for: ${listenFor?.inSeconds ?? 'unlimited'} seconds');
    debugPrint('Pause for: ${pauseFor?.inSeconds ?? 'default'} seconds');

    await _speechToText.listen(
      onResult: (final result) {
        debugPrint(
          'Speech recognition result: "${result.recognizedWords}" '
          '(final: ${result.finalResult}, confidence: ${result.confidence})',
        );
        onResult(result.recognizedWords);
      },
      localeId: localeId,
      listenFor: listenFor,
      pauseFor: pauseFor,
      onSoundLevelChange: (final level) {
        debugPrint('Sound level: $level');
      },
      listenOptions: SpeechListenOptions(),
    );
  }

  /// Stop listening
  static Future<void> stopListening() async {
    if (_isInitialized && _speechToText.isListening) {
      debugPrint('Stopping speech recognition...');
      await _speechToText.stop();
      debugPrint('Speech recognition stopped');
    } else {
      debugPrint('Speech recognition was not active or not initialized');
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
