import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/speech_service.dart';
import '../../services/tts_service.dart';

class SpeechPracticeScreen extends StatefulWidget {
  const SpeechPracticeScreen({this.language = 'English', super.key});

  final String language;

  @override
  State<SpeechPracticeScreen> createState() => _SpeechPracticeScreenState();
}

class _SpeechPracticeScreenState extends State<SpeechPracticeScreen> {
  final TtsService _ttsService = TtsService();
  final SpeechService _speechService = SpeechService();

  bool _isListening = false;
  String _transcript = '';
  int _score = 0;
  String _feedback = '';

  static const Map<String, String> _samplePhrases = {
    'English': 'Hello, how are you today?',
    'isiZulu': 'Sawubona, unjani?',
    'French': 'Bonjour, comment allez-vous?',
    'Spanish': 'Hola, ¿cómo estás?',
  };

  String get _targetPhrase => _samplePhrases[widget.language] ?? _samplePhrases['English']!;

  Future<void> _listenPhrase() async {
    await _ttsService.speak(_targetPhrase, widget.language);
  }

  Future<void> _startOrStopListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() {
        _isListening = false;
      });
      _evaluateResult();
      return;
    }

    final bool granted = await _speechService.requestPermission();
    if (!granted) {
      if (!mounted) return;
      await _showPermissionDialog();
      return;
    }

    setState(() {
      _isListening = true;
      _transcript = '';
      _score = 0;
      _feedback = '';
    });

    await _speechService.startListening((text) {
      if (!mounted) return;
      setState(() {
        _transcript = text;
      });
    });
  }

  void _evaluateResult() {
    final Map<String, dynamic> result =
        _speechService.evaluatePronunciation(_transcript, _targetPhrase);
    setState(() {
      _score = result['score'] as int? ?? 0;
      _feedback = result['feedback'] as String? ?? '';
    });
  }

  Future<void> _showPermissionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Microphone Permission Needed'),
          content: const Text(
            'LinguaFlow needs microphone access so you can practice pronunciation.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await openAppSettings();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _reset() {
    setState(() {
      _isListening = false;
      _transcript = '';
      _score = 0;
      _feedback = '';
    });
  }

  @override
  void dispose() {
    _speechService.stopListening();
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speech Practice')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    Text(
                      _targetPhrase,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.language,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: _listenPhrase,
                    child: const Text('🔊 Listen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startOrStopListening,
                    child: Text(_isListening ? '⏹ Stop' : '🎤 Speak'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: _isListening ? 52 : 0,
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: _isListening
                  ? const Text(
                      'Listening...',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 14),
            if (_transcript.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _transcript,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: _score / 100),
            const SizedBox(height: 8),
            Text(
              _feedback.isEmpty ? 'Speak to get feedback' : _feedback,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _reset,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
