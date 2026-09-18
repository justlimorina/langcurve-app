import '../models/curve_data_point.dart';
import 'database_service.dart';

class TrackingService {
  static final TrackingService instance = TrackingService._internal();
  TrackingService._internal();

  /// Calculates time-series data points for the Learning Curve analytics
  Future<List<CurveDataPoint>> getLearningCurveData() async {
    final logs = await DatabaseService.instance.getReviewLogs();

    if (logs.isEmpty) {
      // Return simulated initial baseline curve if user has just started
      final now = DateTime.now();
      return List.generate(5, (index) {
        final date = now.subtract(Duration(days: 4 - index));
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        return CurveDataPoint(
          date: dateStr,
          wordCount: (index + 1) * 2,
          avgEasiness: 2.5 + (index * 0.05),
          correctReviews: (index + 1) * 2,
          wrongReviews: 0,
        );
      });
    }

    final dayMap = <String, _DayStat>{};

    for (final log in logs) {
      final date = log.createdAt;
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final stat = dayMap.putIfAbsent(dateKey, () => _DayStat());
      stat.count++;
      stat.totalEF += log.easiness;
      if (log.quality >= 3) {
        stat.correct++;
      } else {
        stat.wrong++;
      }
    }

    final points = dayMap.entries.map((entry) {
      final s = entry.value;
      return CurveDataPoint(
        date: entry.key,
        wordCount: s.count,
        avgEasiness: double.parse((s.totalEF / s.count).toStringAsFixed(2)),
        correctReviews: s.correct,
        wrongReviews: s.wrong,
      );
    }).toList();

    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }
}

class _DayStat {
  int count = 0;
  double totalEF = 0.0;
  int correct = 0;
  int wrong = 0;
}
