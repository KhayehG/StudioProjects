import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/lesson.dart';
import '../../services/lesson_service.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final LessonService _lessonService = LessonService();
  final List<Lesson> _lessons = <Lesson>[];
  bool _isLoading = true;
  String _selectedLanguage = 'All';
  String _selectedDifficulty = 'All';

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        context.go('/login');
      }
      return;
    }
    try {
      final List<Lesson> lessons = await _lessonService.fetchAllLessons(uid);
      if (!mounted) return;
      setState(() {
        _lessons
          ..clear()
          ..addAll(lessons);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading lessons: $e')),
      );
    }
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  List<Lesson> get _filteredLessons {
    return _lessons.where((Lesson lesson) {
      final bool languageMatch =
          _selectedLanguage == 'All' || lesson.language == _selectedLanguage;
      final bool difficultyMatch = _selectedDifficulty == 'All' ||
          lesson.difficulty.toLowerCase() ==
              _selectedDifficulty.toLowerCase();
      return languageMatch && difficultyMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> languages = <String>[
      'All',
      ..._lessons
          .map((Lesson l) => l.language)
          .where((s) => s.isNotEmpty)
          .toSet(),
    ];
    final List<String> difficulties = <String>[
      'All',
      ..._lessons
          .map((Lesson l) => l.difficulty)
          .where((s) => s.isNotEmpty)
          .map((d) => d.toLowerCase())
          .toSet()
          .map((d) => d[0].toUpperCase() + d.substring(1)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration:
                    const InputDecoration(labelText: 'Language'),
                    items: languages
                        .map(
                          (lang) => DropdownMenuItem<String>(
                        value: lang,
                        child: Text(lang),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedLanguage = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDifficulty,
                    decoration:
                    const InputDecoration(labelText: 'Difficulty'),
                    items: difficulties
                        .map(
                          (diff) => DropdownMenuItem<String>(
                        value: diff,
                        child: Text(diff),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedDifficulty = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredLessons.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.menu_book,
                      size: 56, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No lessons available'),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredLessons.length,
              itemBuilder: (context, index) {
                final Lesson lesson = _filteredLessons[index];
                return Card(
                  child: ListTile(
                    onTap: () => context
                        .push('/lesson-detail/${lesson.id}'),
                    title: Text(lesson.title),
                    subtitle: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 6),
                        Text(lesson.description),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: <Widget>[
                            Chip(
                              label: Text(lesson.language),
                            ),
                            Chip(
                              backgroundColor:
                              _difficultyColor(
                                  lesson.difficulty),
                              label: Text(
                                lesson.difficulty.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: lesson.isCompleted
                        ? const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}