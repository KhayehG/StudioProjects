import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/progress.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserProgress> getUserProgress(String userId) async {
    final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await _firestore.collection('users').doc(userId).get();
    final QuerySnapshot<Map<String, dynamic>> quizResultsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('quizResults')
        .orderBy('timestamp', descending: true)
        .limit(7)
        .get();
    final QuerySnapshot<Map<String, dynamic>> lessonsSnapshot =
        await _firestore.collection('lessons').get();

    final Map<String, dynamic> userData = userSnapshot.data() ?? <String, dynamic>{};
    final List<dynamic> completedLessons =
        userData['completedLessons'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> badgesRaw =
        userData['badgesEarned'] as List<dynamic>? ?? <dynamic>[];
    final int wordsReviewed = (userData['totalWordsReviewed'] as num?)?.toInt() ?? 0;
    final int currentStreak = (userData['currentStreak'] as num?)?.toInt() ?? 0;
    final int xp = (userData['xp'] as num?)?.toInt() ?? 0;
    final String currentLevel =
        (userData['currentLevel'] as String?)?.trim().isNotEmpty == true
            ? (userData['currentLevel'] as String).trim().toLowerCase()
            : 'beginner';

    final List<Map<String, dynamic>> recentQuizScores = quizResultsSnapshot.docs.map((doc) {
      final data = doc.data();
      final int percentage = (data['percentage'] as num?)?.toInt() ?? 0;
      final Timestamp? ts = data['timestamp'] as Timestamp?;
      return <String, dynamic>{
        'percentage': percentage,
        'timestamp': ts?.toDate(),
      };
    }).toList();

    final double averageQuizScore = recentQuizScores.isEmpty
        ? 0
        : recentQuizScores
                .map((e) => (e['percentage'] as num?)?.toDouble() ?? 0)
                .reduce((a, b) => a + b) /
            recentQuizScores.length;

    return UserProgress(
      lessonsCompleted: completedLessons.length,
      totalLessons: lessonsSnapshot.docs.length,
      wordsReviewed: wordsReviewed,
      currentStreak: currentStreak,
      badgesEarned: badgesRaw.map((e) => e.toString()).toList(),
      recentQuizScores: recentQuizScores,
      averageQuizScore: averageQuizScore,
      xp: xp,
      currentLevel: currentLevel,
    );
  }

  Future<void> updateStreak(String userId) async {
    final DocumentReference<Map<String, dynamic>> userRef =
        _firestore.collection('users').doc(userId);
    final DocumentSnapshot<Map<String, dynamic>> userSnapshot = await userRef.get();
    final Map<String, dynamic> userData = userSnapshot.data() ?? <String, dynamic>{};

    final Timestamp? lastActiveTs = userData['lastActiveDate'] as Timestamp?;
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    int streak = (userData['currentStreak'] as num?)?.toInt() ?? 0;

    if (lastActiveTs == null) {
      streak = 1;
    } else {
      final DateTime lastActive = lastActiveTs.toDate();
      final DateTime lastDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
      final int dayDiff = today.difference(lastDay).inDays;

      if (dayDiff <= 0) {
        return;
      } else if (dayDiff == 1) {
        streak += 1;
      } else {
        streak = 1;
      }
    }

    await userRef.set(
      <String, dynamic>{
        'currentStreak': streak,
        'lastActiveDate': Timestamp.fromDate(today),
      },
      SetOptions(merge: true),
    );

    if (streak == 7) {
      await userRef.set(
        <String, dynamic>{
          'badgesEarned': FieldValue.arrayUnion(<String>['Week Streak']),
        },
        SetOptions(merge: true),
      );
    }
  }
}
