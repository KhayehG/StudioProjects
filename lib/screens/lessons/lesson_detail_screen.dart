import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/lesson.dart';
import '../../services/lesson_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final LessonService _lessonService = LessonService();
  final TtsService _ttsService = TtsService();
  Lesson? _lesson;
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    final Lesson? lesson = await _lessonService.fetchLessonById(widget.lessonId);
    if (!mounted) {
      return;
    }
    setState(() {
      _lesson = lesson;
      _isLoading = false;
    });
  }

  void _completeLesson() {
    if (_isCompleted) {
      return;
    }
    setState(() {
      _isCompleted = true;
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

    if (_lesson == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFEEF0F5),
        appBar: AppBar(
          title: const Text('Lesson'),
          backgroundColor: const Color(0xFFEEF0F5),
          foregroundColor: const Color(0xFF2D2F45),
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Lesson not found',
            style: TextStyle(color: Color(0xFF2D2F45)),
          ),
        ),
      );
    }

    final Lesson lesson = _lesson!;
    final int totalSteps = lesson.contentSteps.length;
    final bool hasSteps = totalSteps > 0;
    final int lastIndex = totalSteps > 0 ? totalSteps - 1 : 0;
    final int safeIndex =
        hasSteps ? _currentIndex.clamp(0, lastIndex) : 0;
    final double progress = hasSteps ? (safeIndex + 1) / totalSteps : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F5),
      appBar: AppBar(
        title: Text(lesson.title),
        backgroundColor: const Color(0xFFEEF0F5),
        foregroundColor: const Color(0xFF2D2F45),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  color: const Color(0xFF5B6BE8),
                  backgroundColor: const Color(0xFFEEF0F5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSteps ? 'Step ${safeIndex + 1} of $totalSteps' : 'Step 0 of 0',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2F45),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: NeuCard(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      hasSteps
                          ? lesson.contentSteps[safeIndex]
                          : 'No lesson content.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2D2F45),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            GradientButton(
              label: '▶ Listen',
              onPressed: hasSteps
                  ? () => _ttsService.speak(
                        lesson.contentSteps[safeIndex],
                        lesson.language,
                      )
                  : null,
            ),
            const SizedBox(height: 12),
            if (hasSteps && _currentIndex < lesson.contentSteps.length - 1)
              GradientButton(
                label: 'Next →',
                onPressed: () => setState(() => _currentIndex++),
              ),
            if (hasSteps && _currentIndex == lesson.contentSteps.length - 1) ...<Widget>[
              GradientButton(
                label: 'Complete Lesson ✅',
                onPressed: _isCompleted ? null : _completeLesson,
                color: const Color(0xFF00b894),
              ),
              const SizedBox(height: 12),
              if (_isCompleted)
                GradientButton(
                  label: 'Take Quiz 📝',
                  onPressed: () => context.push('/quiz/${lesson.id}'),
                  color: const Color(0xFF6C5CE7),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
