import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/lesson.dart';
import 'local_storage_service.dart';

class LessonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _localStorageService = LocalStorageService();

  Future<List<Lesson>> fetchAllLessons(String userId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> lessonsSnapshot =
          await _firestore.collection('lessons').get();
      final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await _firestore.collection('users').doc(userId).get();

      final Map<String, dynamic> userData = userSnapshot.data() ?? <String, dynamic>{};
      final List<dynamic> completedRaw =
          userData['completedLessons'] as List<dynamic>? ?? <dynamic>[];
      final Set<String> completedIds =
          completedRaw.map((dynamic e) => e.toString()).toSet();

      final List<Lesson> lessons = lessonsSnapshot.docs.map((doc) {
        final Lesson lesson = Lesson.fromMap(doc.id, doc.data());
        lesson.isCompleted = completedIds.contains(doc.id);
        return lesson;
      }).toList();

      final List<Lesson> localLessons = await _localStorageService.getAllLessons();
      if (lessons.length > localLessons.length) {
        await _localStorageService.clearAndInsertAll(lessons);
      }
      return lessons;
    } catch (_) {
      return _localStorageService.getAllLessons();
    }
  }

  Future<Lesson?> fetchLessonById(String id) async {
    final Lesson? localLesson = await _localStorageService.getLessonById(id);
    if (localLesson != null) return localLesson;

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('lessons').doc(id).get();
      final Map<String, dynamic>? data = snapshot.data();
      if (data == null) return null;

      final Lesson lesson = Lesson.fromMap(snapshot.id, data);
      await _localStorageService.insertLesson(lesson);
      return lesson;
    } catch (_) {
      return null;
    }
  }

  Future<void> markLessonComplete(
    String lessonId,
    String userId,
    String lessonTitle,
  ) async {
    final DocumentReference<Map<String, dynamic>> userRef =
        _firestore.collection('users').doc(userId);
    final DocumentSnapshot<Map<String, dynamic>> userSnapshot = await userRef.get();
    final Map<String, dynamic> userData = userSnapshot.data() ?? <String, dynamic>{};
    final List<dynamic> completedBefore =
        userData['completedLessons'] as List<dynamic>? ?? <dynamic>[];

    await userRef.set(
      <String, dynamic>{
        'completedLessons': FieldValue.arrayUnion(<String>[lessonId]),
      },
      SetOptions(merge: true),
    );

    await _localStorageService.updateCompletion(lessonId, true);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastLessonTitle', lessonTitle);

    if (completedBefore.isEmpty) {
      await userRef.set(
        <String, dynamic>{
          'badgesEarned': FieldValue.arrayUnion(<String>['First Lesson']),
        },
        SetOptions(merge: true),
      );
    }
  }
}
