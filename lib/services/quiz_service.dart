import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/lesson.dart';
import '../models/quiz.dart';
import '../utils/constants.dart';
import 'lesson_service.dart';
import 'xp_service.dart';

class QuizSaveOutcome {
  const QuizSaveOutcome({
    required this.passed,
    required this.totalXpEarned,
  });

  final bool passed;
  final int totalXpEarned;
}

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Quiz?> fetchQuizByLessonId(String lessonId) async {
    debugPrint('QUIZ_SERVICE: Searching quiz for lessonId=$lessonId');
    final QuerySnapshot<Map<String, dynamic>> query = await _firestore
        .collection('quizzes')
        .where('lessonId', isEqualTo: lessonId)
        .limit(1)
        .get();
    debugPrint(
      'QUIZ_SERVICE: Firestore returned ${query.docs.length} documents for lessonId=$lessonId',
    );

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    debugPrint('QUIZ_SERVICE: First quiz data: ${doc.data()}');
    return Quiz.fromMap(doc.id, doc.data());
  }

  Future<QuizSaveOutcome> saveQuizResult(
    String userId,
    String quizId,
    int score,
    int total,
  ) async {
    final int percentage = total == 0 ? 0 : ((score / total) * 100).round();
    final DocumentReference<Map<String, dynamic>> userRef =
        _firestore.collection('users').doc(userId);

    final DocumentSnapshot<Map<String, dynamic>> userSnap = await userRef.get();
    final Map<String, dynamic> userData = userSnap.data() ?? <String, dynamic>{};
    final List<dynamic> completedRaw =
        userData['completedLessons'] as List<dynamic>? ?? <dynamic>[];
    final Set<String> alreadyCompleted =
        completedRaw.map((dynamic e) => e.toString()).toSet();

    await userRef.collection('quizResults').add(<String, dynamic>{
      'quizId': quizId,
      'score': score,
      'total': total,
      'percentage': percentage,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (score == total && total > 0) {
      await userRef.set(
        <String, dynamic>{
          'badgesEarned': FieldValue.arrayUnion(<String>['Quiz Master']),
        },
        SetOptions(merge: true),
      );
    }

    int xpReward = 0;
    if (percentage == 100) {
      xpReward = AppConstants.xpQuizPassPerfect;
    } else if (percentage >= 80) {
      xpReward = AppConstants.xpQuizPassGood;
    } else if (percentage >= 60) {
      xpReward = AppConstants.xpQuizPass;
    }

    final bool passed = percentage >= 60;
    int totalXpEarned = 0;

    if (passed) {
      await XpService().awardXp(userId, xpReward);
      totalXpEarned += xpReward;

      final DocumentSnapshot<Map<String, dynamic>> quizDoc =
          await _firestore.collection('quizzes').doc(quizId).get();
      final String lessonId = (quizDoc.data()?['lessonId'] ?? '').toString();
      if (lessonId.isNotEmpty && !alreadyCompleted.contains(lessonId)) {
        final DocumentSnapshot<Map<String, dynamic>> lessonDoc =
            await _firestore.collection('lessons').doc(lessonId).get();
        final Lesson lesson = Lesson.fromMap(
          lessonDoc.id,
          lessonDoc.data() ?? <String, dynamic>{},
        );
        final String lessonTitle = lesson.title.trim().isEmpty ? 'Lesson' : lesson.title;

        await LessonService().markLessonComplete(
          lessonId,
          userId,
          lessonTitle,
          quizPassed: true,
        );
        totalXpEarned += lesson.xpReward;
      }
    }

    return QuizSaveOutcome(
      passed: passed,
      totalXpEarned: totalXpEarned,
    );
  }
}
