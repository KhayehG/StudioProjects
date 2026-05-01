import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  static const Map<String, String> _localeMap = {
    'English': 'en-US',
    'isiZulu': 'zu-ZA',
    'French': 'fr-FR',
    'Spanish': 'es-ES',
  };

  Future<void> speak(String text, String language) async {
    await _tts.setLanguage(_localeMap[language] ?? 'en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.speak(text);
  }

  Future<void> stop() async => await _tts.stop();
}
