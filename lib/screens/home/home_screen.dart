import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/progress_service.dart';
import '../../services/seeder_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProgressService _progressService = ProgressService();
  bool _isLoading = true;
  String _userName = 'Learner';
  String _lastLessonTitle = 'Start your first lesson!';
  String? _recommendedLessonId;
  String _recommendedLessonTitle = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() => _isLoading = true);
    await SeederService().seedAll();
    await _loadUserData();
    if (mounted) {
      setState(() => _isLoading = false);
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

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? savedLesson = prefs.getString('lastLessonTitle');
      await _progressService.updateStreak(uid);

      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final QuerySnapshot<Map<String, dynamic>> lessonsSnapshot =
          await FirebaseFirestore.instance.collection('lessons').get();

      final Map<String, dynamic>? data = userDoc.data();
      final List<dynamic> completedLessonsRaw =
          data?['completedLessons'] as List<dynamic>? ?? <dynamic>[];
      final Set<String> completedLessonIds =
          completedLessonsRaw.map((e) => e.toString()).toSet();
      final String fetchedName = (data?['name'] as String?)?.trim().isNotEmpty == true
          ? (data?['name'] as String).trim()
          : 'Learner';

      String? recommendedId;
      String recommendedTitle = '';

      for (final lessonDoc in lessonsSnapshot.docs) {
        if (!completedLessonIds.contains(lessonDoc.id)) {
          recommendedId = lessonDoc.id;
          recommendedTitle = (lessonDoc.data()['title'] as String?)?.trim() ?? '';
          break;
        }
      }

      if (recommendedId == null) {
        final QuerySnapshot<Map<String, dynamic>> lowestQuizResult = await FirebaseFirestore
            .instance
            .collection('users')
            .doc(uid)
            .collection('quizResults')
            .orderBy('percentage')
            .limit(1)
            .get();

        if (lowestQuizResult.docs.isNotEmpty) {
          final String quizId = (lowestQuizResult.docs.first.data()['quizId'] ?? '').toString();
          if (quizId.isNotEmpty) {
            final DocumentSnapshot<Map<String, dynamic>> quizDoc =
                await FirebaseFirestore.instance.collection('quizzes').doc(quizId).get();
            final String lessonId = (quizDoc.data()?['lessonId'] ?? '').toString();
            if (lessonId.isNotEmpty) {
              final DocumentSnapshot<Map<String, dynamic>> lessonDoc =
                  await FirebaseFirestore.instance.collection('lessons').doc(lessonId).get();
              final String title = (lessonDoc.data()?['title'] ?? '').toString().trim();
              if (title.isNotEmpty) {
                recommendedId = lessonId;
                recommendedTitle = title;
              }
            }
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _userName = fetchedName;
        _lastLessonTitle = (savedLesson == null || savedLesson.trim().isEmpty)
            ? 'Start your first lesson!'
            : savedLesson;
        _recommendedLessonId = recommendedId;
        _recommendedLessonTitle = recommendedTitle;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load home data: $error')),
      );
    }
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 36, color: const Color(0xFF2196F3)),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Hello, $_userName 👋',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recommended For You',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _recommendedLessonId == null || _recommendedLessonTitle.isEmpty
                            ? 'No recommendation available yet'
                            : 'We recommend: $_recommendedLessonTitle',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _recommendedLessonId == null
                          ? null
                          : () => context.go('/lesson-detail/$_recommendedLessonId'),
                      child: const Text('Start'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF42A5F5), Color(0xFF1E88E5)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Continue Learning',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lastLessonTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                _buildFeatureCard(
                  icon: Icons.menu_book,
                  label: 'Lessons',
                  onTap: () => context.go('/lessons'),
                ),
                _buildFeatureCard(
                  icon: Icons.translate,
                  label: 'Vocabulary',
                  onTap: () => context.go('/vocabulary'),
                ),
                _buildFeatureCard(
                  icon: Icons.smart_toy,
                  label: 'Chatbot',
                  onTap: () => context.go('/chatbot'),
                ),
                _buildFeatureCard(
                  icon: Icons.bar_chart,
                  label: 'Progress',
                  onTap: () => context.go('/progress'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
