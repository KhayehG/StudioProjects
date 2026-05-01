import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/lesson.dart';
import '../../services/lesson_service.dart';
import '../../services/tts_service.dart';

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
  bool _isCompleting = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    final Lesson? lesson = await _lessonService.fetchLessonById(widget.lessonId);
    if (!mounted) return;
    setState(() {
      _lesson = lesson;
      _isLoading = false;
    });
  }

  Future<void> _completeLesson() async {
    if (_lesson == null || _isCompleting) return;
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) context.go('/login');
      return;
    }

    setState(() {
      _isCompleting = true;
    });

    try {
      await _lessonService.markLessonComplete(_lesson!.id, uid, _lesson!.title);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Congratulations!'),
            content: const Text('You have completed this lesson.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Great'),
              ),
            ],
          );
        },
      );
      if (mounted) {
        context.pop();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to complete lesson: $error')),
      );
      setState(() {
        _isCompleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lesson')),
        body: const Center(
          child: Text('Lesson not found'),
        ),
      );
    }

    final int totalSteps = _lesson!.contentSteps.length;
    final bool hasSteps = totalSteps > 0;
    final int safeIndex = hasSteps ? _currentIndex.clamp(0, totalSteps - 1) : 0;
    final bool isFinalStep = hasSteps && safeIndex == totalSteps - 1;
    final double progress = hasSteps ? (safeIndex + 1) / totalSteps : 0;

    return Scaffold(
      appBar: AppBar(title: Text(_lesson!.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              hasSteps ? 'Step ${safeIndex + 1} of $totalSteps' : 'Step 0 of 0',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  hasSteps ? _lesson!.contentSteps[safeIndex] : 'No lesson content.',
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: hasSteps
                      ? () => _ttsService.speak(
                            _lesson!.contentSteps[safeIndex],
                            _lesson!.language,
                          )
                      : null,
                  icon: const Icon(Icons.volume_up),
                  label: const Text('▶ Listen'),
                ),
                ElevatedButton(
                  onPressed: hasSteps && !isFinalStep
                      ? () {
                          setState(() {
                            _currentIndex++;
                          });
                        }
                      : null,
                  child: const Text('Next'),
                ),
                ElevatedButton(
                  onPressed: hasSteps && isFinalStep && !_isCompleting
                      ? _completeLesson
                      : null,
                  child: _isCompleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Complete Lesson ✅'),
                ),
                OutlinedButton(
                  onPressed: () => context.push('/quiz/${_lesson!.id}'),
                  child: const Text('Take Quiz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
