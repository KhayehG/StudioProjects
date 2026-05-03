import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/lesson.dart';
import '../../services/lesson_service.dart';
import '../../services/xp_service.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neu_pill.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final LessonService _lessonService = LessonService();
  final XpService _xpService = XpService();
  final List<Lesson> _lessons = <Lesson>[];
  bool _isLoading = true;
  String _selectedLanguage = 'All';
  String _selectedDifficulty = 'All';
  int _userXp = 0;
  final Map<String, bool> _lessonUnlocked = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  int _difficultyRank(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return 0;
      case 'intermediate':
        return 1;
      case 'advanced':
        return 2;
      default:
        return 3;
    }
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
      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final Map<String, dynamic>? userData = userDoc.data();
      final int xp = (userData?['xp'] as num?)?.toInt() ?? 0;
      final List<dynamic> completedRaw =
          userData?['completedLessons'] as List<dynamic>? ?? <dynamic>[];
      final List<String> completedIds =
          completedRaw.map((dynamic e) => e.toString()).where((String s) => s.isNotEmpty).toList();

      final Map<String, bool> unlocked = <String, bool>{};
      for (final Lesson lesson in lessons) {
        final bool seq = await _xpService.isLessonUnlocked(
          uid,
          lesson.id,
          lesson.language,
          lesson.difficulty,
          lesson.order,
          completedIds,
        );
        final bool lev = _xpService.isLevelUnlocked(xp, lesson.difficulty);
        unlocked[lesson.id] = seq && lev;
      }

      lessons.sort((Lesson a, Lesson b) {
        final int dr = _difficultyRank(a.difficulty).compareTo(_difficultyRank(b.difficulty));
        if (dr != 0) return dr;
        return a.order.compareTo(b.order);
      });

      if (!mounted) return;
      setState(() {
        _lessons
          ..clear()
          ..addAll(lessons);
        _userXp = xp;
        _lessonUnlocked
          ..clear()
          ..addAll(unlocked);
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

  Color _difficultyPillColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF27A06A);
      case 'intermediate':
        return const Color(0xFFE0903A);
      case 'advanced':
        return const Color(0xFFE05A5A);
      default:
        return const Color(0xFF5B6BE8);
    }
  }

  int _xpRequiredForDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'intermediate':
        return AppConstants.xpIntermediateMin;
      case 'advanced':
        return AppConstants.xpAdvancedMin;
      default:
        return AppConstants.xpBeginnerMin;
    }
  }

  int _xpShortfallForDifficulty(String difficulty) {
    final int need = _xpRequiredForDifficulty(difficulty);
    if (_userXp >= need) return 0;
    return need - _userXp;
  }

  List<Lesson> get _filteredLessons {
    final List<Lesson> list = _lessons.where((Lesson lesson) {
      final bool languageMatch =
          _selectedLanguage == 'All' || lesson.language == _selectedLanguage;
      final bool difficultyMatch = _selectedDifficulty == 'All' ||
          lesson.difficulty.toLowerCase() == _selectedDifficulty.toLowerCase();
      return languageMatch && difficultyMatch;
    }).toList();
    list.sort((Lesson a, Lesson b) {
      final int dr = _difficultyRank(a.difficulty).compareTo(_difficultyRank(b.difficulty));
      if (dr != 0) return dr;
      return a.order.compareTo(b.order);
    });
    return list;
  }

  void _onLessonTap(Lesson lesson) {
    final bool levelOk = _xpService.isLevelUnlocked(_userXp, lesson.difficulty);
    final bool accessible = _lessonUnlocked[lesson.id] ?? false;

    if (lesson.isCompleted) {
      context.push('/lesson-detail/${lesson.id}');
      return;
    }
    if (!levelOk) {
      final int short = _xpShortfallForDifficulty(lesson.difficulty);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You need $short more XP to unlock this level')),
      );
      return;
    }
    if (!accessible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete the previous lesson first')),
      );
      return;
    }
    context.push('/lesson-detail/${lesson.id}');
  }

  @override
  Widget build(BuildContext context) {
    final List<String> languages = <String>[
      'All',
      ..._lessons
          .map((Lesson l) => l.language)
          .where((String s) => s.isNotEmpty)
          .toSet(),
    ];
    final List<String> difficulties = <String>[
      'All',
      ..._lessons
          .map((Lesson l) => l.difficulty)
          .where((String s) => s.isNotEmpty)
          .map((String d) => d.toLowerCase())
          .toSet()
          .map((String d) => d[0].toUpperCase() + d.substring(1)),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F5),
      appBar: AppBar(
        title: const Text('Lessons'),
        elevation: 0,
        backgroundColor: const Color(0xFFEEF0F5),
        foregroundColor: const Color(0xFF2D2F45),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: NeuCard(
                    small: true,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            // ignore: deprecated_member_use
                            value: _selectedLanguage,
                            dropdownColor: const Color(0xFFEEF0F5),
                            decoration: const InputDecoration(labelText: 'Language'),
                            items: languages
                                .map(
                                  (String lang) => DropdownMenuItem<String>(
                                    value: lang,
                                    child: Text(
                                      lang,
                                      style: const TextStyle(color: Color(0xFF2D2F45)),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (String? value) {
                              if (value == null) return;
                              setState(() => _selectedLanguage = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            // ignore: deprecated_member_use
                            value: _selectedDifficulty,
                            dropdownColor: const Color(0xFFEEF0F5),
                            decoration: const InputDecoration(labelText: 'Difficulty'),
                            items: difficulties
                                .map(
                                  (String diff) => DropdownMenuItem<String>(
                                    value: diff,
                                    child: Text(
                                      diff,
                                      style: const TextStyle(color: Color(0xFF2D2F45)),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (String? value) {
                              if (value == null) return;
                              setState(() => _selectedDifficulty = value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredLessons.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(Icons.menu_book, size: 56, color: Color(0xFF9A9EB5)),
                              SizedBox(height: 10),
                              Text(
                                'No lessons available',
                                style: TextStyle(color: Color(0xFF2D2F45)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredLessons.length,
                          itemBuilder: (BuildContext context, int index) {
                            final Lesson lesson = _filteredLessons[index];
                            final bool levelOk =
                                _xpService.isLevelUnlocked(_userXp, lesson.difficulty);
                            final bool accessible = _lessonUnlocked[lesson.id] ?? false;
                            final bool completed = lesson.isCompleted;
                            final Color titleColor = (!levelOk || (!accessible && !completed))
                                ? const Color(0xFF9A9EB5)
                                : const Color(0xFF2D2F45);

                            return NeuCard(
                              small: true,
                              margin: const EdgeInsets.only(bottom: 12),
                              onTap: () => _onLessonTap(lesson),
                              child: Opacity(
                                opacity: completed ? 0.88 : 1.0,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            lesson.title,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: titleColor,
                                            ),
                                          ),
                                          if (!completed && !levelOk) ...<Widget>[
                                            const SizedBox(height: 6),
                                            Text(
                                              'Requires ${_xpRequiredForDifficulty(lesson.difficulty)} XP — currently $_userXp XP',
                                              style: const TextStyle(
                                                color: Color(0xFF9A9EB5),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ] else if (!completed && !accessible) ...<Widget>[
                                            const SizedBox(height: 6),
                                            const Text(
                                              'Complete previous lesson to unlock',
                                              style: TextStyle(
                                                color: Color(0xFF9A9EB5),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Text(
                                            lesson.description,
                                            style: const TextStyle(
                                              color: Color(0xFF9A9EB5),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: <Widget>[
                                        NeuPill(
                                          label: lesson.language,
                                          textColor: const Color(0xFF5B6BE8),
                                        ),
                                        const SizedBox(height: 6),
                                        NeuPill(
                                          label: lesson.difficulty,
                                          textColor: _difficultyPillColor(lesson.difficulty),
                                        ),
                                        const SizedBox(height: 8),
                                        if (completed)
                                          const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF27A06A),
                                            size: 28,
                                          )
                                        else if (!levelOk || !accessible)
                                          const Icon(
                                            Icons.lock,
                                            color: Color(0xFF9A9EB5),
                                            size: 28,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
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
