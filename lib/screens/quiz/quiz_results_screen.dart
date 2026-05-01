import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/quiz_service.dart';

class QuizResultsScreen extends StatefulWidget {
  const QuizResultsScreen({
    required this.quizId,
    required this.score,
    required this.total,
    super.key,
  });

  final String quizId;
  final int score;
  final int total;

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  final QuizService _quizService = QuizService();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _saveResult();
  }

  Future<void> _saveResult() async {
    if (_saved) return;
    _saved = true;
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await _quizService.saveQuizResult(
      userId,
      widget.quizId,
      widget.score,
      widget.total,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int percentage =
        widget.total == 0 ? 0 : ((widget.score / widget.total) * 100).round();
    final bool passed = percentage >= 60;
    final bool earnedBadge = percentage >= 80;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Results')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${widget.score} / ${widget.total}',
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '$percentage%',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                passed ? 'PASSED ✅' : 'FAILED ❌',
                style: TextStyle(
                  color: passed ? Colors.green : Colors.red,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              if (earnedBadge) ...<Widget>[
                const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
                const SizedBox(height: 8),
                const Text(
                  'Badge Earned! 🏆',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
              ],
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Retry Quiz'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.go('/lessons'),
                      child: const Text('Back to Lessons'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
