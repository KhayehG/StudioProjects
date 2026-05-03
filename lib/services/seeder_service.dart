import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SeederService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedAll() async {
    try {
      debugPrint('SEEDER: Starting seedAll...');
      await seedLessons();
      await seedQuizzes();
      await seedSignLessons();
      debugPrint('SEEDER: seedAll complete.');
    } catch (e) {
      debugPrint('SEEDER ERROR in seedAll: $e');
    }
  }

  List<Map<String, dynamic>> _lessonDataList() {
    return <Map<String, dynamic>>[
      {
        'title': 'English Basics',
        'description': 'Learn everyday English words and phrases',
        'language': 'English',
        'difficulty': 'beginner',
        'order': 1,
        'xpReward': 10,
        'quizXpReward': 20,
        'contentSteps': <String>[
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
        'order': 1,
        'xpReward': 10,
        'quizXpReward': 20,
        'contentSteps': <String>[
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
        'order': 1,
        'xpReward': 10,
        'quizXpReward': 20,
        'contentSteps': <String>[
          'Un = 1, Deux = 2, Trois = 3',
          'Quatre = 4, Cinq = 5, Six = 6',
          'Sept = 7, Huit = 8, Neuf = 9',
          'Dix = 10. Practice counting aloud.',
          'Try: Deux + Trois = Cinq. Math in French!',
        ],
      },
      {
        'title': 'English Intermediate',
        'description': 'Expand your English with common phrases',
        'language': 'English',
        'difficulty': 'intermediate',
        'order': 1,
        'xpReward': 20,
        'quizXpReward': 35,
        'contentSteps': <String>[
          'Could you please help me? is a polite request.',
          'I would like to... is used to express a desire.',
          'What time does it open? asks about business hours.',
          'How much does this cost? asks about price.',
          'I am looking for... is used when searching for something.',
        ],
      },
      {
        'title': 'isiZulu Intermediate',
        'description': 'Learn intermediate isiZulu phrases',
        'language': 'isiZulu',
        'difficulty': 'intermediate',
        'order': 1,
        'xpReward': 20,
        'quizXpReward': 35,
        'contentSteps': <String>[
          'Ngicela usizo means Please help me.',
          'Ngifuna ukuya e... means I want to go to...',
          'Ngiyabonga kakhulu means Thank you very much.',
          'Isikhathi sini? means What time is it?',
          'Ingabe uyakhuluma isiZulu? means Do you speak isiZulu?',
        ],
      },
      {
        'title': 'French Phrases',
        'description': 'Learn essential French conversational phrases',
        'language': 'French',
        'difficulty': 'intermediate',
        'order': 1,
        'xpReward': 20,
        'quizXpReward': 35,
        'contentSteps': <String>[
          'Excusez-moi means Excuse me.',
          'Pouvez-vous maider? means Can you help me?',
          'Je voudrais... means I would like...',
          'Combien ca coute? means How much does it cost?',
          'Je ne comprends pas means I do not understand.',
        ],
      },
      {
        'title': 'English Advanced',
        'description': 'Master complex English expressions',
        'language': 'English',
        'difficulty': 'advanced',
        'order': 1,
        'xpReward': 30,
        'quizXpReward': 50,
        'contentSteps': <String>[
          'Despite the challenges, she persevered and succeeded.',
          'The implications of this decision are far-reaching.',
          'He eloquently articulated his perspective to the board.',
          'The phenomenon remains largely unexplained by science.',
          'Their collaborative efforts yielded remarkable results.',
        ],
      },
      {
        'title': 'isiZulu Advanced',
        'description': 'Advanced isiZulu language and culture',
        'language': 'isiZulu',
        'difficulty': 'advanced',
        'order': 1,
        'xpReward': 30,
        'quizXpReward': 50,
        'contentSteps': <String>[
          'Ubuntu ngumuntu ngabantu means a person is a person through other people.',
          'Isibongo is a praise poem used to honour a person or clan.',
          'Ukuhlonipha is a custom of showing deep respect to elders.',
          'Umuntu akalahlwa means no person should be abandoned.',
          'Indlela ibuzwa kwabaphambili means ask those who came before you.',
        ],
      },
      {
        'title': 'French Advanced',
        'description': 'Advanced French language and expressions',
        'language': 'French',
        'difficulty': 'advanced',
        'order': 1,
        'xpReward': 30,
        'quizXpReward': 50,
        'contentSteps': <String>[
          'Il faut cultiver notre jardin means we must cultivate our garden.',
          'La langue est la maison de letre means language is the house of being.',
          'Chaque instant de la vie est un pas vers la mort is a philosophical phrase.',
          'Les absents ont toujours tort means those who are absent are always wrong.',
          'Mieux vaut tard que jamais means better late than never.',
        ],
      },
    ];
  }

  Future<void> seedLessons() async {
    try {
      debugPrint('SEEDER: Checking lessons...');
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _db.collection('lessons').get();

      final List<Map<String, dynamic>> lessonData = _lessonDataList();

      if (snapshot.docs.isEmpty) {
        debugPrint('SEEDER: No lessons found. Seeding all lessons...');
        for (final Map<String, dynamic> data in lessonData) {
          await _db.collection('lessons').add(data);
          debugPrint('SEEDER: Added lesson: ${data['title']}');
        }
        debugPrint('SEEDER: All lessons seeded.');
      } else {
        debugPrint('SEEDER: Lessons exist. Updating with XP fields...');
        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
          final Map<String, dynamic> data = doc.data();
          final bool needsUpdate = data['order'] == null ||
              data['xpReward'] == null ||
              data['quizXpReward'] == null;

          if (needsUpdate) {
            final String title = data['title'] as String? ?? '';
            final Map<String, dynamic> matching = lessonData.firstWhere(
              (Map<String, dynamic> l) =>
                  (l['title'] as String).toLowerCase() == title.toLowerCase(),
              orElse: () => <String, dynamic>{
                'order': 1,
                'xpReward': 10,
                'quizXpReward': 20,
              },
            );
            if (matching.containsKey('title')) {
              await doc.reference.update(<String, dynamic>{
                'order': matching['order'],
                'xpReward': matching['xpReward'],
                'quizXpReward': matching['quizXpReward'],
                'difficulty': matching['difficulty'] ?? data['difficulty'],
                'language': matching['language'] ?? data['language'],
              });
            } else {
              await doc.reference.update(<String, dynamic>{
                'order': matching['order'],
                'xpReward': matching['xpReward'],
                'quizXpReward': matching['quizXpReward'],
              });
            }
            debugPrint('SEEDER: Updated lesson: $title with XP fields');
          }
        }

        final Set<String> existingTitles = snapshot.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                  (d.data()['title'] as String? ?? '').toLowerCase(),
            )
            .toSet();

        for (final Map<String, dynamic> data in lessonData) {
          final String title = (data['title'] as String).toLowerCase();
          if (!existingTitles.contains(title)) {
            await _db.collection('lessons').add(data);
            debugPrint('SEEDER: Added missing lesson: ${data['title']}');
          }
        }
        debugPrint('SEEDER: Lesson sync complete.');
      }
    } catch (e, stack) {
      debugPrint('SEEDER ERROR in seedLessons: $e');
      debugPrint('SEEDER STACK: $stack');
    }
  }

  Future<void> seedQuizzes() async {
    try {
      debugPrint('SEEDER: Checking quizzes...');
      final QuerySnapshot<Map<String, dynamic>> quizSnapshot =
          await _db.collection('quizzes').get();

      if (quizSnapshot.docs.length >= 9) {
        debugPrint('SEEDER: Quizzes already exist (>=9). Skipping.');
        return;
      }

      debugPrint('SEEDER: Clearing ${quizSnapshot.docs.length} quiz doc(s) and re-seeding...');
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in quizSnapshot.docs) {
        await doc.reference.delete();
      }

      final QuerySnapshot<Map<String, dynamic>> allLessons =
          await _db.collection('lessons').get();
      if (allLessons.docs.isEmpty) {
        debugPrint('SEEDER ERROR: No lessons found for quiz seeding!');
        return;
      }

      final Map<String, String> titleToLessonId = <String, String>{};
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in allLessons.docs) {
        final String key = (doc.data()['title'] as String? ?? '').toLowerCase();
        if (key.isNotEmpty) {
          titleToLessonId[key] = doc.id;
        }
      }

      String? lessonIdForTitle(String title) {
        return titleToLessonId[title.toLowerCase()];
      }

      final List<Map<String, dynamic>> quizPayloads = <Map<String, dynamic>>[
        <String, dynamic>{
          '_title': 'English Basics',
          'language': 'English',
          'questions': <Map<String, dynamic>>[
            <String, dynamic>{
              'questionText': 'What does Hello mean?',
              'options': <String>['A greeting', 'A farewell', 'A question', 'A number'],
              'correctAnswer': 'A greeting',
              'explanation': 'Hello is used to greet someone.',
            },
            <String, dynamic>{
              'questionText': 'Which phrase asks about wellbeing?',
              'options': <String>['My name is', 'Goodbye', 'How are you?', 'Please'],
              'correctAnswer': 'How are you?',
              'explanation': 'How are you? asks about someones wellbeing.',
            },
            <String, dynamic>{
              'questionText': 'What does Thank you express?',
              'options': <String>['Anger', 'Gratitude', 'Confusion', 'A greeting'],
              'correctAnswer': 'Gratitude',
              'explanation': 'Thank you expresses appreciation.',
            },
          ],
        },
        <String, dynamic>{
          '_title': 'isiZulu Greetings',
          'language': 'isiZulu',
          'questions': <Map<String, dynamic>>[
            <String, dynamic>{
              'questionText': 'What does Sawubona mean?',
              'options': <String>['Goodbye', 'Hello to one person', 'How are you?', 'I am well'],
              'correctAnswer': 'Hello to one person',
              'explanation': 'Sawubona greets a single person.',
            },
            <String, dynamic>{
              'questionText': 'How do you say I am well in isiZulu?',
              'options': <String>['Sawubona', 'Sala kahle', 'Ngiyaphila', 'Sanibonani'],
              'correctAnswer': 'Ngiyaphila',
              'explanation': 'Ngiyaphila means I am well.',
            },
            <String, dynamic>{
              'questionText': 'What does Sala kahle mean?',
              'options': <String>['Hello', 'How are you?', 'Goodbye to someone staying', 'I am well'],
              'correctAnswer': 'Goodbye to someone staying',
              'explanation': 'Sala kahle is said to someone staying behind.',
            },
          ],
        },
        <String, dynamic>{
          '_title': 'French Numbers',
          'language': 'French',
          'questions': <Map<String, dynamic>>[
            <String, dynamic>{
              'questionText': 'What is Un in English?',
              'options': <String>['One', 'Two', 'Three', 'Four'],
              'correctAnswer': 'One',
              'explanation': 'Un means One in French.',
            },
            <String, dynamic>{
              'questionText': 'What is Cinq in English?',
              'options': <String>['Three', 'Four', 'Five', 'Six'],
              'correctAnswer': 'Five',
              'explanation': 'Cinq means Five in French.',
            },
            <String, dynamic>{
              'questionText': 'What is Dix in English?',
              'options': <String>['Eight', 'Nine', 'Ten', 'Seven'],
              'correctAnswer': 'Ten',
              'explanation': 'Dix means Ten in French.',
            },
          ],
        },
        <String, dynamic>{
          '_title': 'English Intermediate',
          'language': 'English',
          'questions': <Map<String, dynamic>>[
            <String, dynamic>{
              'questionText': 'Which phrase is a polite request?',
              'options': <String>[
                'Could you please help me?',
                'Go away',
                'I do not care',
                'Leave me alone',
              ],
              'correctAnswer': 'Could you please help me?',
              'explanation': 'Could you please is a polite way to ask for help.',
            },
            <String, dynamic>{
              'questionText': 'What does I would like to express?',
              'options': <String>['A command', 'A desire', 'A question', 'A refusal'],
              'correctAnswer': 'A desire',
              'explanation': 'I would like to expresses what you want.',
            },
            <String, dynamic>{
              'questionText': 'How do you ask about price?',
              'options': <String>[
                'What time does it open?',
                'Where is it?',
                'How much does this cost?',
                'Who made this?',
              ],
              'correctAnswer': 'How much does this cost?',
              'explanation': 'How much does this cost asks about the price.',
            },
          ],
        },
        <String, dynamic>{
          '_title': 'isiZulu Intermediate',
          'language': 'isiZulu',
          'questions': <Map<String, dynamic>>[
            <String, dynamic>{
              'questionText': 'What does Ngicela usizo mean?',
              'options': <String>['Thank you', 'Please help me', 'I am going', 'Good morning'],
              'correctAnswer': 'Please help me',
              'explanation': 'Ngicela usizo means please help me.',
            },
            <String, dynamic>{
              'questionText': 'How do you say Thank you very much in isiZulu?',
              'options': <String>['Sawubona', 'Ngiyaphila', 'Ngiyabonga kakhulu', 'Unjani'],
              'correctAnswer': 'Ngiyabonga kakhulu',
              'explanation': 'Ngiyabonga kakhulu means thank you very much.',
            },
            <String, dynamic>{
              'questionText': 'What does Isikhathi sini? mean?',
              'options': <String>['Where are you?', 'What time is it?', 'Who are you?', 'How are you?'],
              'correctAnswer': 'What time is it?',
              'explanation': 'Isikhathi sini asks about the time.',
            },
          ],
        },
        <String, dynamic>{
          '_title': 'French Phrases',
          'language': 'French',
          'questions': <Map<String, dynamic>>[
            <String, dynamic>{
              'questionText': 'What does Excusez-moi mean?',
              'options': <String>['Thank you', 'Excuse me', 'Goodbye', 'Please'],
              'correctAnswer': 'Excuse me',
              'explanation': 'Excusez-moi means excuse me in French.',
            },
            <String, dynamic>{
              'questionText': 'How do you say I would like in French?',
              'options': <String>['Je suis', 'Je voudrais', 'Je parle', 'Je mange'],
              'correctAnswer': 'Je voudrais',
              'explanation': 'Je voudrais means I would like.',
            },
            <String, dynamic>{
              'questionText': 'What does Je ne comprends pas mean?',
              'options': <String>[
                'I understand',
                'I do not speak French',
                'I do not understand',
                'I need help',
              ],
              'correctAnswer': 'I do not understand',
              'explanation': 'Je ne comprends pas means I do not understand.',
            },
          ],
        },
        <String, dynamic>{
          '_title': 'English Advanced',
          'language': 'English',
          'questions': <Map<String, dynamic>>[
            <String, dynamic>{
              'questionText': 'What does eloquently mean?',
              'options': <String>['Loudly', 'Rudely', 'Expressively and clearly', 'Slowly'],
              'correctAnswer': 'Expressively and clearly',
              'explanation': 'Eloquently means expressing oneself clearly and effectively.',
            },
            <String, dynamic>{
              'questionText': 'What does persevered mean?',
              'options': <String>[
                'Gave up easily',
                'Continued despite difficulty',
                'Spoke loudly',
                'Made a mistake',
              ],
              'correctAnswer': 'Continued despite difficulty',
              'explanation': 'Persevered means to continue despite challenges.',
            },
            <String, dynamic>{
              'questionText': 'What does far-reaching mean?',
              'options': <String>[
                'Physically distant',
                'Having wide impact or effect',
                'Difficult to reach',
                'Very expensive',
              ],
              'correctAnswer': 'Having wide impact or effect',
              'explanation': 'Far-reaching means having broad consequences.',
            },
          ],
        },
        <String, dynamic>{
          '_title': 'isiZulu Advanced',
          'language': 'isiZulu',
          'questions': <Map<String, dynamic>>[
            <String, dynamic>{
              'questionText': 'What does Ubuntu mean in short?',
              'options': <String>[
                'I am alone',
                'A person is a person through other people',
                'Work hard always',
                'Never give up',
              ],
              'correctAnswer': 'A person is a person through other people',
              'explanation': 'Ubuntu teaches humanity and community.',
            },
            <String, dynamic>{
              'questionText': 'What is an Isibongo?',
              'options': <String>[
                'A traditional dance',
                'A type of food',
                'A praise poem',
                'A greeting',
              ],
              'correctAnswer': 'A praise poem',
              'explanation': 'Isibongo is a praise poem honouring a person or clan.',
            },
            <String, dynamic>{
              'questionText': 'What does Ukuhlonipha mean?',
              'options': <String>[
                'To celebrate',
                'To show deep respect to elders',
                'To sing loudly',
                'To cook food',
              ],
              'correctAnswer': 'To show deep respect to elders',
              'explanation': 'Ukuhlonipha is a custom of respect in Zulu culture.',
            },
          ],
        },
        <String, dynamic>{
          '_title': 'French Advanced',
          'language': 'French',
          'questions': <Map<String, dynamic>>[
            <String, dynamic>{
              'questionText': 'What does Mieux vaut tard que jamais mean?',
              'options': <String>[
                'Never be late',
                'Better late than never',
                'Time is money',
                'Be on time always',
              ],
              'correctAnswer': 'Better late than never',
              'explanation': 'Mieux vaut tard que jamais means better late than never.',
            },
            <String, dynamic>{
              'questionText': 'Les absents ont toujours tort means?',
              'options': <String>[
                'Those present are always right',
                'Those who are absent are always wrong',
                'Absence makes the heart grow fonder',
                'The truth is always present',
              ],
              'correctAnswer': 'Those who are absent are always wrong',
              'explanation': 'This French proverb blames those who are not present.',
            },
            <String, dynamic>{
              'questionText': 'What is the meaning of Ubuntu in the French lesson context?',
              'options': <String>[
                'A French word for community',
                'Not mentioned in French Advanced',
                'A philosophical concept about humanity',
                'A type of French poetry',
              ],
              'correctAnswer': 'Not mentioned in French Advanced',
              'explanation': 'Ubuntu is an isiZulu concept, not part of French Advanced.',
            },
          ],
        },
      ];

      for (final Map<String, dynamic> payload in quizPayloads) {
        final String lessonTitle = payload['_title'] as String;
        final String? lessonId = lessonIdForTitle(lessonTitle);
        if (lessonId == null || lessonId.isEmpty) {
          debugPrint('SEEDER ERROR: No lesson id for title=$lessonTitle');
          continue;
        }
        final Map<String, dynamic> toWrite = <String, dynamic>{
          'lessonId': lessonId,
          'language': payload['language'],
          'questions': payload['questions'],
        };
        final DocumentReference<Map<String, dynamic>> ref =
            await _db.collection('quizzes').add(toWrite);
        debugPrint('SEEDER: Added quiz id=${ref.id} lessonId=$lessonId title=$lessonTitle');
      }

      debugPrint('SEEDER: All 9 quizzes seeded successfully.');
    } catch (e, stack) {
      debugPrint('SEEDER ERROR in seedQuizzes: $e');
      debugPrint('SEEDER STACK: $stack');
    }
  }

  Future<void> seedSignLessons() async {
    try {
      debugPrint('SEEDER: Checking sign lessons...');
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _db.collection('sign_lessons').get();
      if (snapshot.docs.length >= 26) {
        debugPrint('SEEDER: Sign lessons exist. Skipping.');
        return;
      }

      debugPrint('SEEDER: Seeding sign language lessons...');

      // Using publicly available ASL hand sign images
      // from SigningSavvy and Lifeprint (public domain)
      final List<Map<String, String>> letters = <Map<String, String>>[
        <String, String>{
          'letter': 'A',
          'description': 'Make a fist with your thumb resting on the side.',
        },
        <String, String>{
          'letter': 'B',
          'description': 'Hold four fingers straight up, thumb folded across palm.',
        },
        <String, String>{
          'letter': 'C',
          'description': 'Curve your hand into a C shape.',
        },
        <String, String>{
          'letter': 'D',
          'description':
              'Index finger points up, other fingers and thumb form a circle.',
        },
        <String, String>{
          'letter': 'E',
          'description': 'Curl all fingers down, thumb tucked under.',
        },
        <String, String>{
          'letter': 'F',
          'description':
              'Index and thumb touch forming a circle, other fingers up.',
        },
        <String, String>{
          'letter': 'G',
          'description': 'Index finger and thumb point sideways like a gun.',
        },
        <String, String>{
          'letter': 'H',
          'description': 'Index and middle fingers point sideways together.',
        },
        <String, String>{
          'letter': 'I',
          'description': 'Pinky finger points up, other fingers in a fist.',
        },
        <String, String>{
          'letter': 'J',
          'description': 'Make I sign then draw a J shape in the air.',
        },
        <String, String>{
          'letter': 'K',
          'description':
              'Index and middle finger up in a V with thumb between them.',
        },
        <String, String>{
          'letter': 'L',
          'description':
              'Index finger points up, thumb points out forming an L.',
        },
        <String, String>{
          'letter': 'M',
          'description': 'Tuck thumb under three fingers folded down.',
        },
        <String, String>{
          'letter': 'N',
          'description': 'Tuck thumb under two fingers folded down.',
        },
        <String, String>{
          'letter': 'O',
          'description': 'All fingers and thumb curve to form an O shape.',
        },
        <String, String>{
          'letter': 'P',
          'description': 'Like K but pointed downward.',
        },
        <String, String>{
          'letter': 'Q',
          'description': 'Like G but pointed downward.',
        },
        <String, String>{
          'letter': 'R',
          'description': 'Cross middle finger over index finger.',
        },
        <String, String>{
          'letter': 'S',
          'description': 'Make a fist with thumb in front of fingers.',
        },
        <String, String>{
          'letter': 'T',
          'description': 'Thumb tucked between index and middle fingers.',
        },
        <String, String>{
          'letter': 'U',
          'description': 'Index and middle fingers point up together.',
        },
        <String, String>{
          'letter': 'V',
          'description': 'Index and middle fingers spread in a V or peace sign.',
        },
        <String, String>{
          'letter': 'W',
          'description': 'Index, middle and ring fingers spread and up.',
        },
        <String, String>{
          'letter': 'X',
          'description': 'Index finger hooked or crooked downward.',
        },
        <String, String>{
          'letter': 'Y',
          'description': 'Thumb and pinky extended, other fingers down.',
        },
        <String, String>{
          'letter': 'Z',
          'description': 'Index finger draws a Z shape in the air.',
        },
      ];

      int order = 1;
      for (final Map<String, String> item in letters) {
        final String letter = item['letter']!;
        await _db.collection('sign_lessons').add(<String, dynamic>{
          'letter': letter,
          'imageUrl':
              'https://www.lifeprint.com/asl101/fingerspelling/abc-gifs/${letter.toLowerCase()}.gif',
          'description': item['description'],
          'language': 'ASL',
          'order': order,
        });
        debugPrint('SEEDER: Added sign lesson: $letter');
        order++;
      }
      debugPrint('SEEDER: All 26 sign lessons seeded.');
    } catch (e, stack) {
      debugPrint('SEEDER ERROR in seedSignLessons: $e');
      debugPrint('SEEDER STACK: $stack');
    }
  }
}
