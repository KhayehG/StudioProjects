import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/certificate_service.dart';
import '../../services/notification_service.dart';
import '../../services/quiz_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/neu_pill.dart';

class QuizResultsScreen extends StatefulWidget {
  const QuizResultsScreen({
    required this.quizId,
    required this.score,
    required this.total,
    required this.lessonDifficulty,
    required this.lessonLanguage,
    super.key,
  });

  final String quizId;
  final int score;
  final int total;
  final String lessonDifficulty;
  final String lessonLanguage;

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  final QuizService _quizService = QuizService();
  final CertificateService _certService = CertificateService();

  bool _saved = false;
  bool _outcomeReady = false;
  bool _passed = false;
  int _xpEarned = 0;

  bool _certificateEarned = false;
  bool _certificateLoading = false;
  String _userName = 'Learner';

  @override
  void initState() {
    super.initState();
    _saveResult();
  }

  Future<void> _saveResult() async {
    if (_saved) {
      return;
    }
    _saved = true;
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _outcomeReady = true;
          _passed = false;
          _xpEarned = 0;
        });
      }
      return;
    }

    final QuizSaveOutcome outcome = await _quizService.saveQuizResult(
      userId,
      widget.quizId,
      widget.score,
      widget.total,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _outcomeReady = true;
      _passed = outcome.passed;
      _xpEarned = outcome.totalXpEarned;
    });

    await _checkAndAwardCertificate(userId);
  }

  Future<void> _checkAndAwardCertificate(String userId) async {
    final int percentage =
        widget.total == 0 ? 0 : ((widget.score / widget.total) * 100).round();
    if (widget.lessonDifficulty.trim().toLowerCase() != 'advanced' ||
        percentage < 80) {
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final String rawName = (userDoc.data()?['name'] as String?)?.trim() ?? '';
      final String displayName = rawName.isNotEmpty ? rawName : 'Learner';

      final bool alreadyEarned =
          await _certService.hasEarnedCertificate(userId, widget.lessonLanguage);
      if (!alreadyEarned) {
        await _certService.saveCertificateEarned(userId, widget.lessonLanguage);
        await NotificationService().showCertificateNotification(
          userName: displayName,
          language: widget.lessonLanguage,
        );
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _userName = displayName;
        _certificateEarned = true;
      });
    } catch (e, st) {
      debugPrint('QuizResultsScreen._checkAndAwardCertificate: $e');
      debugPrint('$st');
    }
  }

  int get _percentage =>
      widget.total == 0 ? 0 : ((widget.score / widget.total) * 100).round();

  Future<void> _downloadCertificate() async {
    if (_certificateLoading) {
      return;
    }
    setState(() => _certificateLoading = true);
    await _certService.generateAndShareCertificate(
      userName: _userName,
      language: widget.lessonLanguage,
      score: _percentage,
      dateEarned: DateTime.now(),
    );
    if (mounted) {
      setState(() => _certificateLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int percentage = _percentage;
    final bool passed = percentage >= 60;
    final bool earnedBadge = percentage >= 80;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F5),
      appBar: AppBar(
        title: const Text('Quiz Results'),
        backgroundColor: const Color(0xFFEEF0F5),
        foregroundColor: const Color(0xFF2D2F45),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (_certificateEarned)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFe67e22),
                      width: 2,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFFe67e22).withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      const Icon(
                        Icons.workspace_premium,
                        color: Color(0xFFe67e22),
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Certificate Earned!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1a1d2e),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You completed ${widget.lessonLanguage} Advanced!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7c82a0),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GradientButton(
                        label: '📥 Download Certificate',
                        icon: Icons.download,
                        color: const Color(0xFFe67e22),
                        onPressed:
                            _certificateLoading ? null : _downloadCertificate,
                        isLoading: _certificateLoading,
                      ),
                    ],
                  ),
                ),
              if (_certificateEarned) const SizedBox(height: 16),
              NeuCard(
                padding: EdgeInsets.zero,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border(
                      left: BorderSide(
                        color: passed
                            ? const Color(0xFF27A06A)
                            : const Color(0xFFE05A5A),
                        width: 3,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      Text(
                        '${widget.score} / ${widget.total}',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2F45),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2F45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                passed ? 'PASSED ✅' : 'FAILED ❌',
                style: TextStyle(
                  color: passed
                      ? const Color(0xFF27A06A)
                      : const Color(0xFFE05A5A),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_outcomeReady) ...<Widget>[
                const SizedBox(height: 12),
                if (_passed)
                  Text(
                    'Lesson Complete! +$_xpEarned XP earned 🎉',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF27A06A),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  const Text(
                    'Quiz failed. Retake to complete this lesson.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFE05A5A),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 12),
                NeuPill(
                  label: _passed ? '$_xpEarned XP earned' : '0 XP earned',
                  icon: Icons.bolt,
                  textColor: const Color(0xFFE0903A),
                ),
              ],
              if (earnedBadge) ...<Widget>[
                const SizedBox(height: 16),
                const Icon(Icons.emoji_events, size: 64, color: Color(0xFFE0903A)),
                const SizedBox(height: 8),
                const Text(
                  'Badge Earned! 🏆',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2F45),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5B6BE8),
                        side: const BorderSide(color: Color(0xFF5B6BE8)),
                      ),
                      child: const Text('Retry Quiz'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GradientButton(
                      label: 'Back to Lessons',
                      onPressed: () => context.go('/lessons'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
