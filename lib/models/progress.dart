class UserProgress {
  final int lessonsCompleted;
  final int totalLessons;
  final int wordsReviewed;
  final int currentStreak;
  final List<String> badgesEarned;
  final List<Map<String, dynamic>> recentQuizScores;
  final double averageQuizScore;

  UserProgress({
    required this.lessonsCompleted,
    required this.totalLessons,
    required this.wordsReviewed,
    required this.currentStreak,
    required this.badgesEarned,
    required this.recentQuizScores,
    required this.averageQuizScore,
  });
}
