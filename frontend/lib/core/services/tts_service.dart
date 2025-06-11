import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  const TTSService._();

  static final FlutterTts _flutterTts = FlutterTts();

  static Future<void> speak({
    required final String text,
    final String language = 'en-US',
    final double volume = 1.0,
    final double pitch = 1.0,
    final double rate = 0.5,
  }) async {
    await _flutterTts.setLanguage(language);
    await _flutterTts.setVolume(volume);
    await _flutterTts.setPitch(pitch);
    await _flutterTts.setSpeechRate(rate);
    await _flutterTts.speak(text);
  }

  static Future<void> stop() async {
    await _flutterTts.stop();
  }

  static Future<void> dispose() async {
    await _flutterTts.stop();
  }
}
