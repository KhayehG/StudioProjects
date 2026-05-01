import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/quiz.dart';
import '../../services/quiz_service.dart';
import 'quiz_results_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizService _quizService = QuizService();
  Quiz? _quiz;
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  int _score = 0;
  int? _selectedOptionIndex;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final Quiz? quiz = await _quizService.fetchQuizByLessonId(widget.lessonId);
      if (!mounted) return;
      setState(() {
        _quiz = quiz;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load quiz: $error')),
      );
    }
  }

  void _answerQuestion(int index) {
    if (_answered || _quiz == null) return;
    final Question q = _quiz!.questions[_currentQuestionIndex];
    final bool isCorrect = q.options[index] == q.correctAnswer;

    setState(() {
      _selectedOptionIndex = index;
      _answered = true;
      if (isCorrect) _score++;
    });
  }

  Color? _optionColor(int index, Question question) {
    if (!_answered) return null;
    final String option = question.options[index];
    if (option == question.correctAnswer) return Colors.green.shade100;
    if (_selectedOptionIndex == index && option != question.correctAnswer) {
      return Colors.red.shade100;
    }
    return null;
  }

  Future<void> _goNext() async {
    if (_quiz == null) return;

    final bool isLast = _currentQuestionIndex == _quiz!.questions.length - 1;
    if (isLast) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => QuizResultsScreen(
            quizId: _quiz!.id,
            score: _score,
            total: _quiz!.questions.length,
          ),
        ),
      );
      if (!mounted) return;
      context.pop();
      return;
    }

    setState(() {
      _currentQuestionIndex++;
      _selectedOptionIndex = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_quiz == null || _quiz!.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('No quiz available for this lesson'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final Question question = _quiz!.questions[_currentQuestionIndex];
    final int total = _quiz!.questions.length;
    final double progress = (_currentQuestionIndex + 1) / total;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 10),
            Text(
              'Question ${_currentQuestionIndex + 1} of $total',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  question.questionText,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...List<Widget>.generate(question.options.length, (int index) {
              final String option = question.options[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _optionColor(index, question),
                  ),
                  onPressed: _answered ? null : () => _answerQuestion(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(option),
                  ),
                ),
              );
            }),
            if (_answered)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    question.explanation,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
            const Spacer(),
            if (_answered)
              ElevatedButton(
                onPressed: _goNext,
                child: const Text('Next ▶'),
              ),
          ],
        ),
      ),
    );
  }
}
