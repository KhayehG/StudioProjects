import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SeederService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedAll() async {
    try {
      debugPrint('SEEDER: Starting seedAll...');
      await seedLessons();
      await seedQuizzes();
      debugPrint('SEEDER: seedAll complete.');
    } catch (e) {
      debugPrint('SEEDER ERROR in seedAll: $e');
    }
  }

  Future<void> seedLessons() async {
    try {
      debugPrint('SEEDER: Checking lessons...');
      final snapshot = await _db.collection('lessons').get();

      if (snapshot.docs.length >= 3) {
        debugPrint('SEEDER: Lessons already exist. Skipping.');
        return;
      }

      debugPrint('SEEDER: Seeding lessons...');

      final lessons = [
        {
          'title': 'English Basics',
          'description': 'Learn everyday English words and phrases',
          'language': 'English',
          'difficulty': 'beginner',
          'contentSteps': [
            'Hello means a greeting used when meeting someone.',
            'Goodbye is used when leaving or ending a conversation.',
            'Please and Thank you are essential polite expressions.',
            'How are you? is a common way to ask about someones wellbeing.',
            'My name is... is how you introduce yourself.',
          ],
        },
        {
          'title': 'isiZulu Greetings',
          'description': 'Master basic isiZulu greetings',
          'language': 'isiZulu',
          'difficulty': 'beginner',
          'contentSteps': [
            'Sawubona means Hello to one person.',
            'Sanibonani means Hello to multiple people.',
            'Unjani? means How are you?',
            'Ngiyaphila means I am well.',
            'Sala kahle means Goodbye (said to someone staying).',
          ],
        },
        {
          'title': 'French Numbers',
          'description': 'Learn numbers 1 to 10 in French',
          'language': 'French',
          'difficulty': 'beginner',
          'contentSteps': [
            'Un = 1, Deux = 2, Trois = 3',
            'Quatre = 4, Cinq = 5, Six = 6',
            'Sept = 7, Huit = 8, Neuf = 9',
            'Dix = 10. Practice counting aloud.',
            'Try: Deux + Trois = Cinq. Math in French!',
          ],
        },
      ];

      for (final lesson in lessons) {
        await _db.collection('lessons').add(lesson);
        debugPrint('SEEDER: Added lesson: ${lesson['title']}');
      }

      debugPrint('SEEDER: All lessons seeded.');
    } catch (e) {
      debugPrint('SEEDER ERROR in seedLessons: $e');
    }
  }

  Future<void> seedQuizzes() async {
    try {
      debugPrint('SEEDER: Checking quizzes...');
      final quizSnapshot = await _db.collection('quizzes').get();
      if (quizSnapshot.docs.length >= 2) {
        debugPrint('SEEDER: Quizzes already exist. Skipping.');
        return;
      }

      debugPrint('SEEDER: Fetching ALL lessons...');
      final allLessons = await _db.collection('lessons').get();

      if (allLessons.docs.isEmpty) {
        debugPrint('SEEDER ERROR: No lessons found!');
        return;
      }

      String? englishLessonId;
      String? zuluLessonId;

      for (final doc in allLessons.docs) {
        final lang = (doc.data()['language'] as String? ?? '').toLowerCase();
        final title = (doc.data()['title'] as String? ?? '').toLowerCase();
        debugPrint('SEEDER: Checking doc id=${doc.id} title=$title lang=$lang');

        if (lang.contains('english') || title.contains('english')) {
          englishLessonId = doc.id;
        }
        if (lang.contains('zulu') || title.contains('zulu')) {
          zuluLessonId = doc.id;
        }
      }

      final ids = allLessons.docs.map((d) => d.id).toList();
      englishLessonId ??= ids[0];
      zuluLessonId ??= ids.length > 1 ? ids[1] : ids[0];

      debugPrint('SEEDER: Writing quiz 1 for lessonId=$englishLessonId');
      final quiz1Ref = await _db.collection('quizzes').add({
        'lessonId': englishLessonId,
        'language': 'English',
        'questions': [
          {
            'questionText': 'What does Hello mean?',
            'options': ['A greeting', 'A farewell', 'A question', 'A number'],
            'correctAnswer': 'A greeting',
            'explanation': 'Hello is used to greet someone.',
          },
          {
            'questionText': 'Which phrase asks about wellbeing?',
            'options': ['My name is', 'Goodbye', 'How are you?', 'Please'],
            'correctAnswer': 'How are you?',
            'explanation': 'How are you? asks about wellbeing.',
          },
          {
            'questionText': 'What does Thank you express?',
            'options': ['Anger', 'Gratitude', 'Confusion', 'A greeting'],
            'correctAnswer': 'Gratitude',
            'explanation': 'Thank you expresses appreciation.',
          },
        ],
      });
      debugPrint('SEEDER: Quiz 1 written with id=${quiz1Ref.id}');

      debugPrint('SEEDER: Writing quiz 2 for lessonId=$zuluLessonId');
      final quiz2Ref = await _db.collection('quizzes').add({
        'lessonId': zuluLessonId,
        'language': 'isiZulu',
        'questions': [
          {
            'questionText': 'What does Sawubona mean?',
            'options': ['Goodbye', 'Hello to one person', 'How are you?', 'I am well'],
            'correctAnswer': 'Hello to one person',
            'explanation': 'Sawubona greets a single person.',
          },
          {
            'questionText': 'How do you say I am well in isiZulu?',
            'options': ['Sawubona', 'Sala kahle', 'Ngiyaphila', 'Sanibonani'],
            'correctAnswer': 'Ngiyaphila',
            'explanation': 'Ngiyaphila means I am well.',
          },
          {
            'questionText': 'What does Sala kahle mean?',
            'options': ['Hello', 'How are you?', 'Goodbye to someone staying', 'I am well'],
            'correctAnswer': 'Goodbye to someone staying',
            'explanation': 'Sala kahle is said to someone staying behind.',
          },
        ],
      });
      debugPrint('SEEDER: Quiz 2 written with id=${quiz2Ref.id}');
      debugPrint('SEEDER: All quizzes seeded successfully!');
    } catch (e, stack) {
      debugPrint('SEEDER ERROR in seedQuizzes: $e');
      debugPrint('SEEDER STACK: $stack');
    }
  }
}
