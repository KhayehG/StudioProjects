import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/progress.dart';
import '../../services/progress_service.dart';
import '../../services/xp_service.dart';
import '../../utils/constants.dart';
import '../../widgets/glass_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ProgressService _progressService = ProgressService();
  final XpService _xpService = XpService();
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

  double _xpProgressBarValue(int xp) {
    if (xp >= AppConstants.xpAdvancedMin) {
      return 1.0;
    }
    if (xp >= AppConstants.xpIntermediateMin) {
      final double span =
          (AppConstants.xpAdvancedMin - AppConstants.xpIntermediateMin).toDouble();
      return ((xp - AppConstants.xpIntermediateMin) / span).clamp(0.0, 1.0);
    }
    return (xp / AppConstants.xpIntermediateMin).clamp(0.0, 1.0);
  }

  Widget _buildStreakCard(UserProgress progress) {
    return NeuCard(
      child: Row(
        children: <Widget>[
          const Icon(Icons.local_fire_department, color: Color(0xFFE0903A), size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${progress.currentStreak}-day streak',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2F45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpCard(UserProgress progress) {
    final int xpToNext = _xpService.xpToNextLevel(progress.xp);
    final double barValue = _xpProgressBarValue(progress.xp);

    return NeuCard(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.bolt, color: Color(0xFFE0903A), size: 26),
                const SizedBox(width: 8),
                Text(
                  '${progress.xp} XP',
                  style: const TextStyle(
                    color: Color(0xFF2D2F45),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              progress.currentLevel.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF5B6BE8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            NeuCard(
              inset: true,
              borderRadius: 12,
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: barValue,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEEF0F5),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5B6BE8)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  '${progress.xp} XP',
                  style: const TextStyle(color: Color(0xFF9A9EB5), fontSize: 12),
                ),
                Text(
                  progress.xp >= AppConstants.xpAdvancedMin
                      ? 'Max level'
                      : '$xpToNext XP to next level',
                  style: const TextStyle(color: Color(0xFF9A9EB5), fontSize: 12),
                ),
              ],
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

    return NeuCard(
      small: true,
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
                  color: const Color(0xFF5B6BE8),
                  backgroundColor: const Color(0xFFD1D3D8),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2F45),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Lessons Completed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2F45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizChart(UserProgress progress) {
    final List<Map<String, dynamic>> scores = progress.recentQuizScores.reversed.toList();

    return NeuCard(
      small: true,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Recent Quiz Scores',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D2F45),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: ColoredBox(
                color: const Color(0xFFEEF0F5),
                child: BarChart(
                  BarChartData(
                  minY: 0,
                  maxY: 100,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: Color(0xFFD1D3D8), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 20,
                        getTitlesWidget: (double value, TitleMeta meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF9A9EB5),
                          ),
                        ),
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
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int idx = value.toInt();
                          if (idx < 0 || idx >= scores.length) return const Text('');
                          final DateTime? dt = scores[idx]['timestamp'] as DateTime?;
                          if (dt == null) return const Text('--/--');
                          final String label = '${dt.month}/${dt.day}';
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF9A9EB5),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List<BarChartGroupData>.generate(scores.length, (int index) {
                    final double y =
                        (scores[index]['percentage'] as num?)?.toDouble() ?? 0;
                    return BarChartGroupData(
                      x: index,
                      barRods: <BarChartRodData>[
                        BarChartRodData(
                          toY: y,
                          color: const Color(0xFF5B6BE8),
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
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
          child: NeuCard(
            small: true,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: <Widget>[
                  const Text(
                    'Words Reviewed',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2F45),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${progress.wordsReviewed}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2F45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: NeuCard(
            small: true,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: <Widget>[
                  const Text(
                    'Avg Quiz Score',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2F45),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${progress.averageQuizScore.round()}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2F45),
                    ),
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
    final List<Map<String, dynamic>> badges = <Map<String, dynamic>>[
      {'name': 'First Lesson', 'icon': Icons.menu_book, 'color': Colors.blue},
      {'name': 'Quiz Master', 'icon': Icons.star, 'color': Colors.amber},
      {'name': 'Vocabulary Pro', 'icon': Icons.translate, 'color': Colors.green},
      {
        'name': 'Week Streak',
        'icon': Icons.local_fire_department,
        'color': Colors.orange,
      },
      {'name': 'Chatbot Buddy', 'icon': Icons.chat, 'color': Colors.purple},
      {'name': 'Intermediate Achiever', 'icon': Icons.military_tech, 'color': Colors.blue},
      {'name': 'Advanced Scholar', 'icon': Icons.workspace_premium, 'color': Colors.purple},
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.45,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: badges.map((Map<String, dynamic> badge) {
        final bool isEarned = earned.contains(badge['name']);
        final Color activeColor = badge['color'] as Color;
        return NeuCard(
          small: true,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  badge['icon'] as IconData,
                  color: isEarned ? activeColor : const Color(0xFF9A9EB5),
                  size: 30,
                ),
                const SizedBox(height: 8),
                Text(
                  badge['name'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2F45),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEarned ? 'Earned' : 'Locked',
                  style: TextStyle(
                    color: isEarned ? const Color(0xFF27A06A) : const Color(0xFF9A9EB5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
        backgroundColor: Color(0xFFEEF0F5),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final UserProgress? progress = _progress;
    if (progress == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFEEF0F5),
        appBar: AppBar(
          title: const Text('Progress'),
          backgroundColor: const Color(0xFFEEF0F5),
          foregroundColor: const Color(0xFF2D2F45),
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Unable to load progress',
            style: TextStyle(color: Color(0xFF2D2F45)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F5),
      appBar: AppBar(
        title: const Text('Progress'),
        backgroundColor: const Color(0xFFEEF0F5),
        foregroundColor: const Color(0xFF2D2F45),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildStreakCard(progress),
            const SizedBox(height: 14),
            _buildXpCard(progress),
            const SizedBox(height: 14),
            _buildLessonProgress(progress),
            const SizedBox(height: 14),
            _buildQuizChart(progress),
            const SizedBox(height: 14),
            _buildStatsRow(progress),
            const SizedBox(height: 14),
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D2F45),
              ),
            ),
            const SizedBox(height: 10),
            _buildBadges(progress),
          ],
        ),
      ),
    );
  }
}
