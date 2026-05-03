import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  Future<bool> requestPermission() async {
    _isInitialized = await _speech.initialize(
      onError: (e) => debugPrint('Speech error: $e'),
    );
    return _isInitialized;
  }

  Future<void> startListening(
    Function(String) onResult, {
    String? localeId,
  }) async {
    if (!_isInitialized) await requestPermission();
    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      localeId: localeId,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Map<String, dynamic> evaluatePronunciation(String transcript, String expected) {
    final t = transcript.toLowerCase().trim();
    final e = expected.toLowerCase().trim();
    if (e.isEmpty) return {'score': 0, 'feedback': 'No phrase'};
    final score = _similarity(t, e);
    String feedback;
    if (score >= 90) {
      feedback = 'Excellent! 🎉';
    } else if (score >= 70) {
      feedback = 'Almost there! 👍';
    } else {
      feedback = 'Try again 🔄';
    }
    return {'score': score, 'feedback': feedback};
  }

  int _similarity(String a, String b) {
    if (a == b) return 100;
    if (b.isEmpty) return 0;
    final distance = _levenshtein(a, b);
    final maxLen = b.length > a.length ? b.length : a.length;
    return ((1 - distance / maxLen) * 100).round().clamp(0, 100);
  }

  int _levenshtein(String a, String b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));
    for (int i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= n; j++) {
      dp[0][j] = j;
    }
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        dp[i][j] = a[i - 1] == b[j - 1]
            ? dp[i - 1][j - 1]
            : 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce(min);
      }
    }
    return dp[m][n];
  }
}
