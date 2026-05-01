class Question {
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  Question({
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory Question.fromMap(Map<String, dynamic> map) => Question(
        questionText: map['questionText'] ?? '',
        options: List<String>.from(map['options'] ?? <String>[]),
        correctAnswer: map['correctAnswer'] ?? '',
        explanation: map['explanation'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'questionText': questionText,
        'options': options,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
      };
}

class Quiz {
  final String id;
  final String lessonId;
  final String language;
  final List<Question> questions;

  Quiz({
    required this.id,
    required this.lessonId,
    required this.language,
    required this.questions,
  });

  factory Quiz.fromMap(String id, Map<String, dynamic> map) => Quiz(
        id: id,
        lessonId: map['lessonId'] ?? '',
        language: map['language'] ?? '',
        questions: (map['questions'] as List<dynamic>? ?? <dynamic>[])
            .map((q) => Question.fromMap(Map<String, dynamic>.from(q)))
            .toList(),
      );
}
