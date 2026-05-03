import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/vocabulary.dart';
import '../../services/vocabulary_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final VocabularyService _vocabularyService = VocabularyService();
  List<VocabularyWord> _dueWords = <VocabularyWord>[];
  int _currentIndex = 0;
  bool _showBack = false;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDueWords();
  }

  Future<void> _loadDueWords() async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    try {
      final List<VocabularyWord> words = await _vocabularyService.fetchDueToday(userId);
      if (!mounted) return;
      setState(() {
        _dueWords = words;
        _currentIndex = 0;
        _showBack = false;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load due words: $error')),
      );
    }
  }

  Future<void> _rateCard(int rating) async {
    if (_isSubmitting || _currentIndex >= _dueWords.length) return;
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _vocabularyService.updateAfterReview(
        userId,
        _dueWords[_currentIndex].id,
        rating,
      );
      if (!mounted) return;
      setState(() {
        _currentIndex++;
        _showBack = false;
        _isSubmitting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review update failed: $error')),
      );
    }
  }

  Widget _buildCardFace(VocabularyWord word) {
    if (_showBack) {
      return Container(
        key: const ValueKey<String>('back'),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              word.translation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2F45),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              word.exampleSentence,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Color(0xFF9A9EB5),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      key: const ValueKey<String>('front'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            word.word,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5B6BE8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            word.language,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF9A9EB5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap to reveal',
            style: TextStyle(
              color: Color(0xFF9A9EB5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFEEF0F5),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_dueWords.isEmpty || _currentIndex >= _dueWords.length) {
      return Scaffold(
        backgroundColor: const Color(0xFFEEF0F5),
        appBar: AppBar(
          title: const Text('Flashcards'),
          backgroundColor: const Color(0xFFEEF0F5),
          foregroundColor: const Color(0xFF2D2F45),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.celebration, size: 72, color: Color(0xFFE0903A)),
                const SizedBox(height: 14),
                const Text(
                  'All done for today! 🎉',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2F45),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                GradientButton(
                  label: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final VocabularyWord current = _dueWords[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F5),
      appBar: AppBar(
        title: const Text('Flashcards'),
        backgroundColor: const Color(0xFFEEF0F5),
        foregroundColor: const Color(0xFF2D2F45),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Text(
              'Card ${_currentIndex + 1} of ${_dueWords.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9A9EB5),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showBack = !_showBack;
                  });
                },
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: NeuCard(
                        child: _buildCardFace(current),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_showBack)
              Row(
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: GradientButton(
                        label: 'Hard',
                        color: const Color(0xFFE05A5A),
                        onPressed: _isSubmitting ? null : () => _rateCard(1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: GradientButton(
                        label: 'Okay',
                        color: const Color(0xFFE0903A),
                        onPressed: _isSubmitting ? null : () => _rateCard(3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: GradientButton(
                        label: 'Easy',
                        color: const Color(0xFF27A06A),
                        onPressed: _isSubmitting ? null : () => _rateCard(5),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
