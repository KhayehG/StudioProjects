import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/progress.dart';
import '../../services/progress_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ProgressService _progressService = ProgressService();
  UserProgress? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      await _progressService.updateStreak(uid);
      final UserProgress progress = await _progressService.getUserProgress(uid);
      if (!mounted) return;
      setState(() {
        _progress = progress;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load progress: $error')),
      );
    }
  }

  Widget _buildStreakCard(UserProgress progress) {
    return Card(
      color: const Color(0xFF2196F3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: <Widget>[
            const Text('🔥', style: TextStyle(fontSize: 34)),
            const SizedBox(width: 12),
            Text(
              '${progress.currentStreak}-day streak',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonProgress(UserProgress progress) {
    final double ratio = progress.totalLessons == 0
        ? 0
        : progress.lessonsCompleted / progress.totalLessons;
    final int percent = (ratio * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Stack(
              alignment: Alignment.center,
              children: <Widget>[
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: ratio.clamp(0, 1),
                    strokeWidth: 9,
                  ),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Lessons Completed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizChart(UserProgress progress) {
    final List<Map<String, dynamic>> scores = progress.recentQuizScores.reversed.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Recent Quiz Scores',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: 100,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: Colors.grey.shade300, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 20,
                        getTitlesWidget: (value, meta) =>
                            Text(value.toInt().toString()),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final int idx = value.toInt();
                          if (idx < 0 || idx >= scores.length) return const Text('');
                          final DateTime? dt = scores[idx]['timestamp'] as DateTime?;
                          if (dt == null) return const Text('--/--');
                          final label = '${dt.month}/${dt.day}';
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(label, style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(scores.length, (index) {
                    final double y =
                        (scores[index]['percentage'] as num?)?.toDouble() ?? 0;
                    return BarChartGroupData(
                      x: index,
                      barRods: <BarChartRodData>[
                        BarChartRodData(
                          toY: y,
                          color: const Color(0xFF2196F3),
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(UserProgress progress) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  const Text(
                    'Words Reviewed',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${progress.wordsReviewed}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  const Text(
                    'Avg Quiz Score',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${progress.averageQuizScore.round()}%',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadges(UserProgress progress) {
    final Set<String> earned = progress.badgesEarned.toSet();
    final badges = <Map<String, dynamic>>[
      {'name': 'First Lesson', 'icon': Icons.menu_book, 'color': Colors.blue},
      {'name': 'Quiz Master', 'icon': Icons.star, 'color': Colors.amber},
      {'name': 'Vocabulary Pro', 'icon': Icons.translate, 'color': Colors.green},
      {
        'name': 'Week Streak',
        'icon': Icons.local_fire_department,
        'color': Colors.orange,
      },
      {'name': 'Chatbot Buddy', 'icon': Icons.chat, 'color': Colors.purple},
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.45,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: badges.map((badge) {
        final bool isEarned = earned.contains(badge['name']);
        final Color activeColor = badge['color'] as Color;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  badge['icon'] as IconData,
                  color: isEarned ? activeColor : Colors.grey,
                  size: 30,
                ),
                const SizedBox(height: 8),
                Text(
                  badge['name'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  isEarned ? 'Earned ✅' : 'Locked 🔒',
                  style: TextStyle(
                    color: isEarned ? Colors.green : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final UserProgress? progress = _progress;
    if (progress == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Progress')),
        body: const Center(child: Text('Unable to load progress')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildStreakCard(progress),
            const SizedBox(height: 14),
            _buildLessonProgress(progress),
            const SizedBox(height: 14),
            _buildQuizChart(progress),
            const SizedBox(height: 14),
            _buildStatsRow(progress),
            const SizedBox(height: 14),
            const Text(
              'Achievements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _buildBadges(progress),
          ],
        ),
      ),
    );
  }
}
