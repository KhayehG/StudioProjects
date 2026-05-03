import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/speech_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/glass_card.dart';

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

  String _selectedLanguage = 'English';
  int _currentPhraseIndex = 0;
  bool _showHint = false;

  /// STT locale ids aligned with [TtsService] / phrase languages.
  static const Map<String, String> _speechLocaleByLanguage = <String, String>{
    'English': 'en-US',
    'isiZulu': 'zu-ZA',
    'French': 'fr-FR',
    'Spanish': 'es-ES',
  };

  static const Map<String, List<Map<String, String>>> _phraseBank = {
    'English': [
      {'phrase': 'Hello, how are you today?', 'hint': 'A common greeting'},
      {
        'phrase': 'My name is and I am learning English.',
        'hint': 'Introducing yourself',
      },
      {
        'phrase': 'Could you please help me?',
        'hint': 'Asking for help politely',
      },
      {
        'phrase': 'Thank you very much for your kindness.',
        'hint': 'Expressing gratitude',
      },
      {
        'phrase': 'I would like to learn more languages.',
        'hint': 'Expressing a desire',
      },
      {
        'phrase': 'What time does the shop open?',
        'hint': 'Asking about time',
      },
      {
        'phrase': 'I do not understand, please repeat that.',
        'hint': 'Asking for clarification',
      },
      {
        'phrase': 'The weather is beautiful today.',
        'hint': 'Talking about weather',
      },
    ],
    'isiZulu': [
      {'phrase': 'Sawubona, unjani namhlanje?', 'hint': 'Hello, how are you today?'},
      {'phrase': 'Igama lami ngi.', 'hint': 'My name is'},
      {'phrase': 'Ngicela usizo.', 'hint': 'Please help me'},
      {'phrase': 'Ngiyabonga kakhulu.', 'hint': 'Thank you very much'},
      {
        'phrase': 'Ngifuna ukufunda izilimi eziningi.',
        'hint': 'I want to learn many languages',
      },
      {'phrase': 'Ivula nini isitolo?', 'hint': 'When does the shop open?'},
      {
        'phrase': 'Angizwa kahle, phinda futhi.',
        'hint': 'I do not hear well, please repeat',
      },
      {'phrase': 'Izulu lihle namhlanje.', 'hint': 'The weather is beautiful today'},
    ],
    'French': [
      {'phrase': 'Bonjour, comment allez-vous?', 'hint': 'Hello, how are you?'},
      {
        'phrase': 'Je mappelle et japprends le francais.',
        'hint': 'My name is and I am learning French',
      },
      {
        'phrase': 'Pouvez-vous maider sil vous plait?',
        'hint': 'Can you help me please?',
      },
      {
        'phrase': 'Merci beaucoup pour votre gentillesse.',
        'hint': 'Thank you very much for your kindness',
      },
      {
        'phrase': 'Je voudrais apprendre plus de langues.',
        'hint': 'I would like to learn more languages',
      },
      {
        'phrase': 'A quelle heure ouvre le magasin?',
        'hint': 'What time does the shop open?',
      },
      {
        'phrase': 'Je ne comprends pas, repetez sil vous plait.',
        'hint': 'I do not understand, please repeat',
      },
      {
        'phrase': 'Il fait beau temps aujourdhui.',
        'hint': 'The weather is beautiful today',
      },
    ],
    'Spanish': [
      {'phrase': 'Hola, como estas hoy?', 'hint': 'Hello, how are you today?'},
      {
        'phrase': 'Me llamo y estoy aprendiendo espanol.',
        'hint': 'My name is and I am learning Spanish',
      },
      {
        'phrase': 'Por favor, puedes ayudarme?',
        'hint': 'Can you please help me?',
      },
      {
        'phrase': 'Muchas gracias por tu amabilidad.',
        'hint': 'Thank you very much for your kindness',
      },
      {
        'phrase': 'Me gustaria aprender mas idiomas.',
        'hint': 'I would like to learn more languages',
      },
      {
        'phrase': 'A que hora abre la tienda?',
        'hint': 'What time does the shop open?',
      },
      {
        'phrase': 'No entiendo, por favor repite eso.',
        'hint': 'I do not understand please repeat that',
      },
      {
        'phrase': 'El tiempo esta hermoso hoy.',
        'hint': 'The weather is beautiful today',
      },
    ],
  };

  Map<String, String> get _currentPhraseData =>
      _phraseBank[_selectedLanguage]![_currentPhraseIndex];

  String get _currentPhrase => _currentPhraseData['phrase']!;

  String get _currentHint => _currentPhraseData['hint']!;

  int get _totalPhrases => _phraseBank[_selectedLanguage]!.length;

  Color get _scoreBarColor {
    if (_score >= 90) return const Color(0xFF27A06A);
    if (_score >= 70) return const Color(0xFFE0903A);
    return const Color(0xFFE05A5A);
  }

  @override
  void initState() {
    super.initState();
    if (_phraseBank.containsKey(widget.language)) {
      _selectedLanguage = widget.language;
    }
  }

  void _clearTranscriptAndScore() {
    _transcript = '';
    _score = 0;
    _feedback = '';
  }

  Future<void> _listenPhrase() async {
    await _ttsService.speak(_currentPhrase, _selectedLanguage);
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
      _clearTranscriptAndScore();
    });

    // isiZulu speech recognition accuracy depends on the device's installed
    // language pack. We pass locale zu-ZA to speech_to_text; if the device
    // does not support it, the engine may fall back to the device default.
    // That is a device-level limitation, not an app bug.
    final String? sttLocale = _speechLocaleByLanguage[_selectedLanguage];

    await _speechService.startListening(
      (String text) {
        if (!mounted) return;
        setState(() {
          _transcript = text;
        });
      },
      localeId: sttLocale,
    );
  }

  void _evaluateResult() {
    final Map<String, dynamic> result =
        _speechService.evaluatePronunciation(_transcript, _currentPhrase);
    setState(() {
      _score = result['score'] as int? ?? 0;
      _feedback = result['feedback'] as String? ?? '';
    });
  }

  Future<void> _showPermissionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
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
            TextButton(
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

  void _onLanguageChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedLanguage = value;
      _currentPhraseIndex = 0;
      _showHint = false;
      _clearTranscriptAndScore();
    });
  }

  Future<void> _goPreviousPhrase() async {
    if (_currentPhraseIndex <= 0) {
      return;
    }
    if (_isListening) {
      await _speechService.stopListening();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isListening = false;
      _currentPhraseIndex--;
      _transcript = '';
      _score = 0;
      _feedback = '';
      _showHint = false;
    });
  }

  Future<void> _goNextOrStartOver() async {
    if (_isListening) {
      await _speechService.stopListening();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isListening = false;
      if (_currentPhraseIndex < _totalPhrases - 1) {
        _currentPhraseIndex++;
      } else {
        _currentPhraseIndex = 0;
      }
      _transcript = '';
      _score = 0;
      _feedback = '';
      _showHint = false;
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
      backgroundColor: const Color(0xFFEEF0F5),
      appBar: AppBar(
        title: const Text('Speech Practice'),
        backgroundColor: const Color(0xFFEEF0F5),
        foregroundColor: const Color(0xFF2D2F45),
        elevation: 0,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: const Color(0xFFEEF0F5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2D2F45)),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2F45),
                  ),
                  dropdownColor: const Color(0xFFEEF0F5),
                  items: _phraseBank.keys
                      .map(
                        (String lang) => DropdownMenuItem<String>(
                          value: lang,
                          child: Text(lang),
                        ),
                      )
                      .toList(),
                  onChanged: _onLanguageChanged,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Phrase ${_currentPhraseIndex + 1} of $_totalPhrases',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9A9EB5),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showHint = !_showHint;
                    });
                  },
                  child: Text(
                    _showHint ? 'Hide hint' : 'Show hint',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5B6BE8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_showHint) ...<Widget>[
              NeuCard(
                small: true,
                padding: const EdgeInsets.all(12),
                child: Text(
                  _currentHint,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF9A9EB5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 16),
            NeuCard(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 120),
                child: Center(
                  child: Text(
                    _currentPhrase,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2F45),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                NeuCard(
                  borderRadius: 32,
                  width: 64,
                  height: 64,
                  padding: EdgeInsets.zero,
                  onTap: _listenPhrase,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.volume_up, color: Color(0xFF5B6BE8), size: 28),
                        SizedBox(height: 2),
                        Text(
                          'Listen',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF9A9EB5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _startOrStopListening,
                  child: _isListening
                      ? Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE05A5A),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: const Color(0xFFE05A5A).withValues(alpha: 0.35),
                                offset: const Offset(3, 3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.mic, color: Colors.white, size: 28),
                              SizedBox(height: 2),
                              Text(
                                'Speak',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        )
                      : NeuCard(
                          borderRadius: 32,
                          width: 64,
                          height: 64,
                          padding: EdgeInsets.zero,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(Icons.mic, color: Color(0xFF5B6BE8), size: 28),
                                SizedBox(height: 2),
                                Text(
                                  'Speak',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF9A9EB5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
            if (_isListening) ...<Widget>[
              const SizedBox(height: 12),
              const Text(
                'Listening…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE05A5A),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (_transcript.isNotEmpty) ...<Widget>[
              NeuCard(
                small: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'You said:',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9A9EB5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _transcript,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D2F45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_score > 0) ...<Widget>[
              NeuCard(
                small: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'Score',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9A9EB5),
                          ),
                        ),
                        Text(
                          '$_score%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5B6BE8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    NeuCard(
                      inset: true,
                      height: 10,
                      borderRadius: 50,
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: SizedBox(
                          height: 10,
                          width: double.infinity,
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: <Widget>[
                              const ColoredBox(
                                color: Color(0xFFEEF0F5),
                                child: SizedBox.expand(),
                              ),
                              FractionallySizedBox(
                                widthFactor: (_score / 100).clamp(0.0, 1.0),
                                heightFactor: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: _scoreBarColor,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _feedback,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2F45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else
              const SizedBox(height: 20),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (_currentPhraseIndex > 0) ...<Widget>[
                  GestureDetector(
                    onTap: () {
                      unawaited(_goPreviousPhrase());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F8),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0xFFd0d3de),
                            offset: Offset(4, 4),
                            blurRadius: 8,
                          ),
                          BoxShadow(
                            color: Colors.white,
                            offset: Offset(-4, -4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.arrow_back_ios,
                            size: 14,
                            color: Color(0xFF7c82a0),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Previous',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7c82a0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                GestureDetector(
                  onTap: () {
                    unawaited(_goNextOrStartOver());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                          offset: const Offset(4, 4),
                          blurRadius: 10,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          offset: const Offset(-3, -3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _currentPhraseIndex < _totalPhrases - 1
                              ? 'Next'
                              : 'Start Over',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _currentPhraseIndex < _totalPhrases - 1
                              ? Icons.arrow_forward_ios
                              : Icons.refresh,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
