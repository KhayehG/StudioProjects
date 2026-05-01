class Lesson {
  final String id;
  final String title;
  final String description;
  final String language;
  final String difficulty;
  final List<String> contentSteps;
  bool isCompleted;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.language,
    required this.difficulty,
    required this.contentSteps,
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
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'language': language,
        'difficulty': difficulty,
        'contentSteps': contentSteps,
        'isCompleted': isCompleted,
      };
}
