import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/lesson.dart';
import '../../models/quiz.dart';
import '../../services/lesson_service.dart';
import '../../services/quiz_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import 'quiz_results_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizService _quizService = QuizService();
  final LessonService _lessonService = LessonService();
  Quiz? _quiz;
  String _lessonDifficulty = '';
  String _lessonLanguage = '';
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final Quiz? quiz = await _quizService.fetchQuizByLessonId(widget.lessonId);
      final Lesson? lesson = await _lessonService.fetchLessonById(widget.lessonId);
      if (!mounted) {
        return;
      }
      setState(() {
        _quiz = quiz;
        _lessonDifficulty = lesson?.difficulty ?? '';
        final String lessonLang = (lesson?.language ?? '').trim();
        _lessonLanguage =
            lessonLang.isNotEmpty ? lessonLang : (quiz?.language ?? '');
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load quiz: $error')),
      );
    }
  }

  void _selectAnswer(String option) {
    if (_answered || _quiz == null) {
      return;
    }
    final Question q = _quiz!.questions[_currentQuestionIndex];
    final bool isCorrect = option == q.correctAnswer;

    setState(() {
      _selectedAnswer = option;
      _answered = true;
      if (isCorrect) {
        _score++;
      }
    });
  }

  Color _getOptionColor(String option) {
    if (_quiz == null) {
      return const Color(0xFFF0F2F8);
    }
    final Question q = _quiz!.questions[_currentQuestionIndex];
    if (!_answered) {
      return const Color(0xFFF0F2F8);
    }
    if (option == q.correctAnswer) {
      return const Color(0xFFE0FAF3);
    }
    if (option == _selectedAnswer && option != q.correctAnswer) {
      return const Color(0xFFFFE8E8);
    }
    return const Color(0xFFF0F2F8);
  }

  Color _getOptionTextColor(String option) {
    if (_quiz == null) {
      return const Color(0xFF1a1d2e);
    }
    final Question q = _quiz!.questions[_currentQuestionIndex];
    if (!_answered) {
      return const Color(0xFF1a1d2e);
    }
    if (option == q.correctAnswer) {
      return const Color(0xFF00b894);
    }
    if (option == _selectedAnswer && option != q.correctAnswer) {
      return const Color(0xFFe74c3c);
    }
    return const Color(0xFF7c82a0);
  }

  Future<void> _goNext() async {
    if (_quiz == null) {
      return;
    }

    final bool isLast = _currentQuestionIndex == _quiz!.questions.length - 1;
    if (isLast) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => QuizResultsScreen(
            quizId: _quiz!.id,
            score: _score,
            total: _quiz!.questions.length,
            lessonDifficulty: _lessonDifficulty,
            lessonLanguage: _lessonLanguage.isNotEmpty
                ? _lessonLanguage
                : _quiz!.language,
          ),
        ),
      );
      if (!mounted) {
        return;
      }
      context.pop();
      return;
    }

    setState(() {
      _currentQuestionIndex++;
      _selectedAnswer = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFEEF0F5),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_quiz == null || _quiz!.questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFEEF0F5),
        appBar: AppBar(
          title: const Text('Quiz'),
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
                const Text(
                  'No quiz available for this lesson',
                  style: TextStyle(color: Color(0xFF2D2F45)),
                ),
                const SizedBox(height: 12),
                GradientButton(
                  onPressed: () => context.pop(),
                  label: 'Back',
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
      backgroundColor: const Color(0xFFEEF0F5),
      appBar: AppBar(
        title: const Text('Quiz'),
        backgroundColor: const Color(0xFFEEF0F5),
        foregroundColor: const Color(0xFF2D2F45),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            NeuCard(
              inset: true,
              borderRadius: 12,
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEEF0F5),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF5B6BE8)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Question ${_currentQuestionIndex + 1} of $total',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2F45),
              ),
            ),
            const SizedBox(height: 14),
            NeuCard(
              child: Text(
                question.questionText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2F45),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ...List<Widget>.generate(question.options.length, (int index) {
                      final String option = question.options[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: _answered
                                ? null
                                : () => _selectAnswer(option),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: _getOptionColor(option),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _answered
                                    ? const <BoxShadow>[]
                                    : const <BoxShadow>[
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
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _getOptionTextColor(option),
                                ),
                                textAlign: TextAlign.left,
                                softWrap: true,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (_answered)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: NeuCard(
                          small: true,
                          child: Text(
                            question.explanation,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF2D2F45),
                            ),
                            softWrap: true,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_answered) ...<Widget>[
              const SizedBox(height: 12),
              GradientButton(
                label: 'Next ▶',
                onPressed: _goNext,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
