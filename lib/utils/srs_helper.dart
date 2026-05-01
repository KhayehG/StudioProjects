class SrsResult {
  final int newInterval;
  final double newEaseFactor;
  final DateTime nextReviewDate;

  SrsResult({
    required this.newInterval,
    required this.newEaseFactor,
    required this.nextReviewDate,
  });
}

SrsResult calculateSrs(int currentInterval, double easeFactor, int rating) {
  double newEF = easeFactor;
  int newInterval;

  if (rating == 1) {
    newInterval = 1;
    newEF = (easeFactor - 0.2).clamp(1.3, 2.5);
  } else if (rating == 3) {
    newInterval = currentInterval;
  } else {
    newInterval = (currentInterval * easeFactor).round();
    newEF = (easeFactor + 0.1).clamp(1.3, 2.5);
  }
  if (newInterval < 1) newInterval = 1;

  return SrsResult(
    newInterval: newInterval,
    newEaseFactor: newEF,
    nextReviewDate: DateTime.now().add(Duration(days: newInterval)),
  );
}
