import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vocabulary.dart';
import '../utils/srs_helper.dart';

class VocabularyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _vocabRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('vocabulary');
  }

  Future<List<VocabularyWord>> fetchAll(String userId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _vocabRef(userId).get();
    return snapshot.docs
        .map((doc) => VocabularyWord.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<VocabularyWord>> fetchDueToday(String userId) async {
    final List<VocabularyWord> words = await fetchAll(userId);
    final DateTime now = DateTime.now();
    return words.where((word) => !word.nextReviewDate.isAfter(now)).toList();
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

  Future<void> updateAfterReview(String userId, String wordId, int rating) async {
    final DocumentReference<Map<String, dynamic>> wordRef = _vocabRef(userId).doc(wordId);
    final DocumentSnapshot<Map<String, dynamic>> wordSnapshot = await wordRef.get();
    final Map<String, dynamic>? data = wordSnapshot.data();
    if (data == null) return;

    final VocabularyWord current = VocabularyWord.fromMap(wordSnapshot.id, data);
    final SrsResult result = calculateSrs(current.interval, current.easeFactor, rating);

    await wordRef.update(<String, dynamic>{
      'interval': result.newInterval,
      'easeFactor': result.newEaseFactor,
      'lastReviewed': Timestamp.fromDate(DateTime.now()),
      'nextReviewDate': Timestamp.fromDate(result.nextReviewDate),
    });

    final DocumentReference<Map<String, dynamic>> userRef =
        _firestore.collection('users').doc(userId);
    await userRef.set(
      <String, dynamic>{'totalWordsReviewed': FieldValue.increment(1)},
      SetOptions(merge: true),
    );

    final DocumentSnapshot<Map<String, dynamic>> userSnapshot = await userRef.get();
    final int totalWordsReviewed =
        (userSnapshot.data()?['totalWordsReviewed'] as num?)?.toInt() ?? 0;
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
