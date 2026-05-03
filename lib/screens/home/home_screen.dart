import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/progress_service.dart';
import '../../services/seeder_service.dart';
import '../../services/xp_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neu_pill.dart';
import '../../widgets/neu_icon_box.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProgressService _progressService = ProgressService();
  bool _isLoading = true;
  String _userName = 'Learner';
  String? _recommendedLessonId;
  String _recommendedLessonTitle = '';
  String _recommendationReason = '';
  bool _recommendationLoading = false;
  int _userXp = 0;
  String _currentLevel = 'beginner';
  int _streak = 0;
  int _lastQuizPercentage = 0;
  static const int _lessonsCompletedToday = 0;

  int get _nextLevelXp =>
      _currentLevel == 'beginner' ? 100 : _currentLevel == 'intermediate' ? 250 : 250;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() => _isLoading = true);
    await SeederService().seedAll();
    await _loadUserData();
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _recommendationLoading = true;
    });
    await _loadRecommendation();
    if (mounted) {
      setState(() {
        _recommendationLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) {
          context.go('/login');
        }
        return;
      }

      await _progressService.updateStreak(uid);

      final DocumentReference<Map<String, dynamic>> userRef =
          FirebaseFirestore.instance.collection('users').doc(uid);
      DocumentSnapshot<Map<String, dynamic>> userDoc = await userRef.get();
      Map<String, dynamic>? data = userDoc.data();
      if (data == null || !data.containsKey('xp') || data['xp'] == null) {
        await userRef.set(
          <String, dynamic>{
            'xp': 0,
            'currentLevel': 'beginner',
          },
          SetOptions(merge: true),
        );
        userDoc = await userRef.get();
        data = userDoc.data();
      }

      final String fetchedName = (data?['name'] as String?)?.trim().isNotEmpty == true
          ? (data?['name'] as String).trim()
          : 'Learner';
      final int userXp = (data?['xp'] as num?)?.toInt() ?? 0;
      final String currentLevelRaw =
          (data?['currentLevel'] as String?)?.trim().isNotEmpty == true
              ? (data?['currentLevel'] as String).trim().toLowerCase()
              : 'beginner';
      final int streak = (data?['currentStreak'] as num?)?.toInt() ?? 0;

      int lastQuizPct = 0;
      final QuerySnapshot<Map<String, dynamic>> recentQuiz = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('quizResults')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      if (recentQuiz.docs.isNotEmpty) {
        lastQuizPct = (recentQuiz.docs.first.data()['percentage'] as num?)?.round() ?? 0;
      }

      if (!mounted) return;

      setState(() {
        _userName = fetchedName;
        _userXp = userXp;
        _currentLevel = currentLevelRaw;
        _streak = streak;
        _lastQuizPercentage = lastQuizPct;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load home data: $error')),
      );
    }
  }

  Future<void> _loadRecommendation() async {
    try {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) {
          setState(() {
            _recommendationLoading = false;
          });
        }
        return;
      }

      int difficultyRank(String difficulty) {
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

      final FirebaseFirestore db = FirebaseFirestore.instance;
      final XpService xpService = XpService();

      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await db.collection('users').doc(uid).get();
      final Map<String, dynamic>? userData = userDoc.data();
      final int userXp = (userData?['xp'] as num?)?.toInt() ?? 0;
      final List<dynamic> completedRaw =
          userData?['completedLessons'] as List<dynamic>? ?? <dynamic>[];
      final List<String> completedLessonIds = completedRaw
          .map((dynamic e) => e.toString())
          .where((String s) => s.isNotEmpty)
          .toList();
      final Set<String> completedSet = completedLessonIds.toSet();
      final String selectedLanguage = (userData?['selectedLanguage'] as String?)?.trim() ?? '';

      final QuerySnapshot<Map<String, dynamic>> lessonsSnapshot =
          await db.collection('lessons').get();
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> sortedLessonDocs =
          List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(lessonsSnapshot.docs)
            ..sort(
              (
                QueryDocumentSnapshot<Map<String, dynamic>> a,
                QueryDocumentSnapshot<Map<String, dynamic>> b,
              ) {
                final int ra = difficultyRank((a.data()['difficulty'] as String?) ?? '');
                final int rb = difficultyRank((b.data()['difficulty'] as String?) ?? '');
                final int byDiff = ra.compareTo(rb);
                if (byDiff != 0) {
                  return byDiff;
                }
                final int oa = (a.data()['order'] as num?)?.toInt() ?? 1;
                final int ob = (b.data()['order'] as num?)?.toInt() ?? 1;
                final int byOrder = oa.compareTo(ob);
                if (byOrder != 0) {
                  return byOrder;
                }
                return a.id.compareTo(b.id);
              },
            );

      final List<QueryDocumentSnapshot<Map<String, dynamic>>> unlockedDocs =
          <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in sortedLessonDocs) {
        final Map<String, dynamic> d = doc.data();
        final String language = (d['language'] as String?)?.trim() ?? '';
        final String difficulty = (d['difficulty'] as String?)?.trim() ?? '';
        final int order = (d['order'] as num?)?.toInt() ?? 1;

        final bool conditionA = xpService.isLevelUnlocked(userXp, difficulty);
        final bool conditionB = await xpService.isLessonUnlocked(
          uid,
          doc.id,
          language,
          difficulty,
          order,
          completedLessonIds,
        );
        if (conditionA && conditionB) {
          unlockedDocs.add(doc);
        }
      }

      final Map<String, String> lessonIdToTitle = <String, String>{};
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in sortedLessonDocs) {
        lessonIdToTitle[doc.id] = (doc.data()['title'] as String?)?.trim() ?? '';
      }

      String? chosenId;
      String chosenTitle = '';
      String chosenReason = '';

      if (selectedLanguage.isNotEmpty) {
        final String sel = selectedLanguage.toLowerCase();
        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in unlockedDocs) {
          final Map<String, dynamic> d = doc.data();
          final String lang = (d['language'] as String?)?.trim() ?? '';
          if (lang.toLowerCase() != sel) {
            continue;
          }
          if (completedSet.contains(doc.id)) {
            continue;
          }
          chosenId = doc.id;
          chosenTitle = lessonIdToTitle[doc.id] ?? '';
          chosenReason = 'Next up in your learning path 🎯';
          break;
        }
      }

      if (chosenId == null) {
        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in unlockedDocs) {
          if (completedSet.contains(doc.id)) {
            continue;
          }
          chosenId = doc.id;
          chosenTitle = lessonIdToTitle[doc.id] ?? '';
          chosenReason = 'Continue where you left off 📚';
          break;
        }
      }

      if (chosenId == null) {
        final QuerySnapshot<Map<String, dynamic>> allResultsSnapshot =
            await db.collection('users').doc(uid).collection('quizResults').get();

        final Set<String> quizIdsNeeded = <String>{};
        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in allResultsSnapshot.docs) {
          final String qid = (doc.data()['quizId'] ?? '').toString();
          if (qid.isNotEmpty) {
            quizIdsNeeded.add(qid);
          }
        }

        final Map<String, String> quizIdToLessonId = <String, String>{};
        for (final String quizId in quizIdsNeeded) {
          final DocumentSnapshot<Map<String, dynamic>> quizDoc =
              await db.collection('quizzes').doc(quizId).get();
          final String? lid = quizDoc.data()?['lessonId'] as String?;
          if (lid != null && lid.isNotEmpty) {
            quizIdToLessonId[quizId] = lid;
          }
        }

        final Map<String, List<int>> scoresByLesson = <String, List<int>>{};
        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in allResultsSnapshot.docs) {
          final Map<String, dynamic> d = doc.data();
          final String quizId = (d['quizId'] ?? '').toString();
          final String? lessonId = quizIdToLessonId[quizId];
          if (lessonId == null || lessonId.isEmpty || !completedSet.contains(lessonId)) {
            continue;
          }
          final int pct = (d['percentage'] as num?)?.round() ?? 0;
          scoresByLesson.putIfAbsent(lessonId, () => <int>[]).add(pct);
        }

        String? worstLessonId;
        double? worstAvg;
        for (final MapEntry<String, List<int>> e in scoresByLesson.entries) {
          final List<int> list = e.value;
          if (list.isEmpty) {
            continue;
          }
          final double avg = list.reduce((int a, int b) => a + b) / list.length;
          if (worstAvg == null || avg < worstAvg) {
            worstAvg = avg;
            worstLessonId = e.key;
          }
        }

        if (worstLessonId != null) {
          chosenId = worstLessonId;
          chosenTitle = lessonIdToTitle[worstLessonId] ?? '';
          chosenReason = 'Practise to improve your score 💪';
        }
      }

      final bool allLessonsComplete = lessonsSnapshot.docs.isNotEmpty &&
          lessonsSnapshot.docs.every(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) => completedSet.contains(d.id),
          );
      if (allLessonsComplete) {
        chosenId = null;
        chosenTitle = '';
        chosenReason = '';
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _recommendedLessonId = chosenId;
        _recommendedLessonTitle = chosenTitle;
        _recommendationReason = chosenReason;
        _recommendationLoading = false;
      });
    } catch (e, st) {
      debugPrint('HomeScreen._loadRecommendation error: $e');
      debugPrint('$st');
      if (mounted) {
        setState(() {
          _recommendationLoading = false;
        });
      }
    }
  }

  String _userInitials() {
    final List<String> parts =
        _userName.trim().split(RegExp(r'\s+')).where((String s) => s.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'LF';
    }
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _getGreeting() {
    final int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    }
    if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    }
    if (hour >= 17 && hour < 21) {
      return 'Good evening';
    }
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFEEF0F5),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final double xpBarFactor =
        _nextLevelXp <= 0 ? 0.0 : (_userXp / _nextLevelXp).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9A9EB5),
                        ),
                      ),
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2F45),
                        ),
                      ),
                    ],
                  ),
                  NeuCard(
                    borderRadius: 50,
                    padding: EdgeInsets.zero,
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Text(
                        _userInitials(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5B6BE8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    NeuPill(
                      label: '$_userXp XP',
                      icon: Icons.bolt,
                      textColor: const Color(0xFFE0903A),
                    ),
                    const SizedBox(width: 10),
                    NeuPill(
                      label: _currentLevel.capitalize(),
                      textColor: const Color(0xFF5B6BE8),
                    ),
                    const SizedBox(width: 10),
                    NeuPill(
                      label: '$_streak day streak',
                      icon: Icons.local_fire_department,
                      textColor: const Color(0xFF27A06A),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              NeuCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'Progress to next level',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9A9EB5),
                          ),
                        ),
                        Text(
                          '$_userXp / $_nextLevelXp XP',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5B6BE8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 8,
                      width: double.infinity,
                      child: NeuCard(
                        inset: true,
                        borderRadius: 50,
                        padding: EdgeInsets.zero,
                        height: 8,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: xpBarFactor,
                              heightFactor: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5B6BE8),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!_recommendationLoading && _recommendedLessonId != null)
                NeuCard(
                  padding: EdgeInsets.zero,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEF0F5),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      border: Border(
                        left: BorderSide(
                          color: Color(0xFF5B6BE8),
                          width: 3,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'UP NEXT',
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                  color: Color(0xFF9A9EB5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _recommendedLessonTitle,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D2F45),
                                ),
                              ),
                              Text(
                                _recommendationReason,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9A9EB5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/lesson-detail/$_recommendedLessonId'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B6BE8),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: const Color(0xFF4A58C8).withValues(alpha: 0.4),
                                  offset: const Offset(3, 3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Text(
                              'Start',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: <Widget>[
                  NeuCard(
                    small: true,
                    onTap: () => context.go('/lessons'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const NeuIconBox(icon: Icons.menu_book, color: Color(0xFF5B6BE8)),
                        const SizedBox(height: 10),
                        const Text(
                          'Lessons',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D2F45),
                          ),
                        ),
                        Text(
                          '9 available',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF9A9EB5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  NeuCard(
                    small: true,
                    onTap: () => context.go('/vocabulary'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const NeuIconBox(icon: Icons.translate, color: Color(0xFF27A06A)),
                        const SizedBox(height: 10),
                        const Text(
                          'Vocabulary',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D2F45),
                          ),
                        ),
                        Text(
                          'Review due',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF9A9EB5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  NeuCard(
                    small: true,
                    onTap: () => context.go('/chatbot'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const NeuIconBox(
                          icon: Icons.chat_bubble_outline,
                          color: Color(0xFFE0903A),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Chatbot',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D2F45),
                          ),
                        ),
                        Text(
                          'Practice AI',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF9A9EB5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  NeuCard(
                    small: true,
                    onTap: () => context.go('/progress'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const NeuIconBox(icon: Icons.bar_chart, color: Color(0xFFE05A5A)),
                        const SizedBox(height: 10),
                        const Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D2F45),
                          ),
                        ),
                        Text(
                          'View stats',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF9A9EB5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  NeuCard(
                    small: true,
                    onTap: () => context.go('/sign-language'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const NeuIconBox(
                          icon: Icons.sign_language,
                          color: Color(0xFF9C27B0),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Sign Language',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D2F45),
                          ),
                        ),
                        Text(
                          'A to Z',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF9A9EB5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              NeuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      "TODAY'S ACTIVITY",
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9A9EB5),
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            Text(
                              '$_lessonsCompletedToday',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D2F45),
                              ),
                            ),
                            const Text(
                              'Lessons',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9A9EB5),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            Text(
                              '$_userXp',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D2F45),
                              ),
                            ),
                            const Text(
                              'XP Today',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9A9EB5),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            Text(
                              '$_lastQuizPercentage%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D2F45),
                              ),
                            ),
                            const Text(
                              'Quiz avg',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9A9EB5),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: <Widget>[
                            Text(
                              '$_streak',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D2F45),
                              ),
                            ),
                            const Text(
                              'Streak',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9A9EB5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExt on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
