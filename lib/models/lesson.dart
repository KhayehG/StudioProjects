class Lesson {
  final String id;
  final String title;
  final String description;
  final String language;
  final String difficulty;
  final List<String> contentSteps;
  final int order;
  final int xpReward;
  final int quizXpReward;
  bool isCompleted;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.language,
    required this.difficulty,
    required this.contentSteps,
    this.order = 1,
    this.xpReward = 10,
    this.quizXpReward = 20,
    this.isCompleted = false,
  });

  factory Lesson.fromMap(String id, Map<String, dynamic> map) {
    return Lesson(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      language: map['language'] ?? '',
      difficulty: map['difficulty'] ?? '',
      contentSteps: List<String>.from(map['contentSteps'] ?? []),
      order: (map['order'] as num?)?.toInt() ?? 1,
      xpReward: (map['xpReward'] as num?)?.toInt() ?? 10,
      quizXpReward: (map['quizXpReward'] as num?)?.toInt() ?? 20,
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'title': title,
        'description': description,
        'language': language,
        'difficulty': difficulty,
        'contentSteps': contentSteps,
        'isCompleted': isCompleted,
        'order': order,
        'xpReward': xpReward,
        'quizXpReward': quizXpReward,
      };
}
