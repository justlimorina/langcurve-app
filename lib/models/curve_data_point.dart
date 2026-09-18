class CurveDataPoint {
  final String date; // YYYY-MM-DD
  final int wordCount;
  final double avgEasiness;
  final int correctReviews;
  final int wrongReviews;

  CurveDataPoint({
    required this.date,
    required this.wordCount,
    required this.avgEasiness,
    required this.correctReviews,
    required this.wrongReviews,
  });

  factory CurveDataPoint.fromMap(Map<String, dynamic> map) {
    return CurveDataPoint(
      date: map['date'] as String,
      wordCount: (map['wordCount'] ?? map['word_count'] ?? 0) as int,
      avgEasiness: ((map['avgEasiness'] ?? map['avg_easiness'] ?? 2.5) as num).toDouble(),
      correctReviews: (map['correctReviews'] ?? map['correct_reviews'] ?? 0) as int,
      wrongReviews: (map['wrongReviews'] ?? map['wrong_reviews'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'wordCount': wordCount,
      'avgEasiness': avgEasiness,
      'correctReviews': correctReviews,
      'wrongReviews': wrongReviews,
    };
  }
}
