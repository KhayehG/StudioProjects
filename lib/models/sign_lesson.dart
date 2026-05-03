class SignLesson {
  final String id;
  final String letter;
  final String imageUrl;
  final String description;
  final String language;
  final int order;

  SignLesson({
    required this.id,
    required this.letter,
    required this.imageUrl,
    required this.description,
    required this.language,
    required this.order,
  });

  factory SignLesson.fromMap(String id, Map<String, dynamic> map) {
    return SignLesson(
      id: id,
      letter: map['letter'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      description: map['description'] as String? ?? '',
      language: map['language'] as String? ?? 'ASL',
      order: (map['order'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'letter': letter,
        'imageUrl': imageUrl,
        'description': description,
        'language': language,
        'order': order,
      };
}
