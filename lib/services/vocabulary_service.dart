import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/vocabulary.dart';
import '../utils/constants.dart';
import '../utils/srs_helper.dart';
import 'xp_service.dart';

class VocabularyService {
  static int _sessionReviewCount = 0;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _vocabRef(String userId) {
    return _db.collection('users').doc(userId).collection('vocabulary');
  }

  Future<List<VocabularyWord>> fetchAll(String userId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _vocabRef(userId).get();
    return snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            VocabularyWord.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<VocabularyWord>> fetchDueToday(String userId) async {
    final List<VocabularyWord> words = await fetchAll(userId);
    final DateTime now = DateTime.now();
    return words
        .where((VocabularyWord word) => !word.nextReviewDate.isAfter(now))
        .toList();
  }

  Future<void> addWord(String userId, Map<String, dynamic> data) async {
    final DateTime now = DateTime.now();
    await _vocabRef(userId).add(<String, dynamic>{
      ...data,
      'interval': 1,
      'easeFactor': 2.5,
      'nextReviewDate': Timestamp.fromDate(now),
      'lastReviewed': Timestamp.fromDate(now),
    });
  }

  Future<void> updateWord(
    String userId,
    String wordId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('vocabulary')
          .doc(wordId)
          .update(updates);
      debugPrint('VOCAB: Updated word $wordId');
    } catch (e) {
      debugPrint('VOCAB update error: $e');
      rethrow;
    }
  }

  Future<void> deleteWord(String userId, String wordId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('vocabulary')
          .doc(wordId)
          .delete();
      debugPrint('VOCAB: Deleted word $wordId');
    } catch (e) {
      debugPrint('VOCAB delete error: $e');
      rethrow;
    }
  }

  Future<void> updateAfterReview(
    String userId,
    String wordId,
    int rating,
  ) async {
    final DocumentReference<Map<String, dynamic>> wordRef =
        _vocabRef(userId).doc(wordId);
    final DocumentSnapshot<Map<String, dynamic>> wordSnapshot =
        await wordRef.get();
    final Map<String, dynamic>? data = wordSnapshot.data();
    if (data == null) {
      return;
    }

    final VocabularyWord current =
        VocabularyWord.fromMap(wordSnapshot.id, data);
    final SrsResult result =
        calculateSrs(current.interval, current.easeFactor, rating);

    await wordRef.update(<String, dynamic>{
      'interval': result.newInterval,
      'easeFactor': result.newEaseFactor,
      'lastReviewed': Timestamp.fromDate(DateTime.now()),
      'nextReviewDate': Timestamp.fromDate(result.nextReviewDate),
    });

    final DocumentReference<Map<String, dynamic>> userRef =
        _db.collection('users').doc(userId);
    final DocumentSnapshot<Map<String, dynamic>> userBefore =
        await userRef.get();
    final int beforeTotal =
        (userBefore.data()?['totalWordsReviewed'] as num?)?.toInt() ?? 0;

    await userRef.set(
      <String, dynamic>{'totalWordsReviewed': FieldValue.increment(1)},
      SetOptions(merge: true),
    );

    final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await userRef.get();
    final int totalWordsReviewed =
        (userSnapshot.data()?['totalWordsReviewed'] as num?)?.toInt() ?? 0;

    _sessionReviewCount += 1;
    debugPrint('VocabularyService: session review count = $_sessionReviewCount');

    if (totalWordsReviewed > 0 && totalWordsReviewed ~/ 10 > beforeTotal ~/ 10) {
      await XpService().awardXp(userId, AppConstants.xpVocabReview10);
      debugPrint('XP: +5 XP for 10 vocabulary reviews');
    }

    if (totalWordsReviewed >= 50) {
      await userRef.set(
        <String, dynamic>{
          'badgesEarned': FieldValue.arrayUnion(<String>['Vocabulary Pro']),
        },
        SetOptions(merge: true),
      );
    }
  }
}
