import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/quiz.dart';

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

  Future<void> saveQuizResult(String userId, String quizId, int score, int total) async {
    final int percentage = total == 0 ? 0 : ((score / total) * 100).round();
    final DocumentReference<Map<String, dynamic>> userRef =
        _firestore.collection('users').doc(userId);

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
  }
}
