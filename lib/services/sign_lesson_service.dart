import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/sign_lesson.dart';

class SignLessonService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<SignLesson>> fetchAllSignLessons() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _db
          .collection('sign_lessons')
          .orderBy('order')
          .get();
      return snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                SignLesson.fromMap(doc.id, doc.data()),
          )
          .toList();
    } catch (e) {
      debugPrint('SignLessonService error: $e');
      return <SignLesson>[];
    }
  }
}
