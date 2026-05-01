import 'package:cloud_firestore/cloud_firestore.dart';

class VocabularyWord {
  final String id;
  final String word;
  final String translation;
  final String language;
  final String exampleSentence;
  final DateTime lastReviewed;
  final DateTime nextReviewDate;
  final int interval;
  final double easeFactor;

  VocabularyWord({
    required this.id,
    required this.word,
    required this.translation,
    required this.language,
    required this.exampleSentence,
    required this.lastReviewed,
    required this.nextReviewDate,
    required this.interval,
    required this.easeFactor,
  });

  factory VocabularyWord.fromMap(String id, Map<String, dynamic> map) {
    return VocabularyWord(
      id: id,
      word: map['word'] ?? '',
      translation: map['translation'] ?? '',
      language: map['language'] ?? '',
      exampleSentence: map['exampleSentence'] ?? '',
      lastReviewed: (map['lastReviewed'] as Timestamp).toDate(),
      nextReviewDate: (map['nextReviewDate'] as Timestamp).toDate(),
      interval: map['interval'] ?? 1,
      easeFactor: (map['easeFactor'] ?? 2.5).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'word': word,
        'translation': translation,
        'language': language,
        'exampleSentence': exampleSentence,
        'lastReviewed': Timestamp.fromDate(lastReviewed),
        'nextReviewDate': Timestamp.fromDate(nextReviewDate),
        'interval': interval,
        'easeFactor': easeFactor,
      };
}
