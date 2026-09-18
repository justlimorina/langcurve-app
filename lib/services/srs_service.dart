import 'dart:math';
import '../core/constants/app_constants.dart';
import '../models/review_log.dart';
import '../models/vocabulary.dart';
import 'database_service.dart';

class Sm2Result {
  final double easiness;
  final int repetitions;
  final int interval;
  final DateTime dueDate;

  Sm2Result({
    required this.easiness,
    required this.repetitions,
    required this.interval,
    required this.dueDate,
  });
}

class SrsService {
  static final SrsService instance = SrsService._internal();
  SrsService._internal();

  /// SuperMemo-2 (SM-2) Algorithm implementation
  Sm2Result calculateSM2({
    required int quality,
    required double currentEF,
    required int currentRepetitions,
    required int currentInterval,
  }) {
    // 1. If quality is poor (< 3), reset consecutive repetitions to 0 and set next review in 1 day
    if (quality < 3) {
      return Sm2Result(
        easiness: max(1.3, currentEF - 0.2),
        repetitions: 0,
        interval: 1,
        dueDate: DateTime.now().add(const Duration(days: 1)),
      );
    }

    // 2. Calculate next repetitions and review interval
    final nextRepetitions = currentRepetitions + 1;
    int nextInterval = 1;

    if (nextRepetitions == 1) {
      nextInterval = 1;
    } else if (nextRepetitions == 2) {
      nextInterval = 6;
    } else {
      nextInterval = (currentInterval * currentEF).round();
      if (nextInterval < 1) nextInterval = 1;
    }

    // 3. Adjust Easiness Factor (EF)
    final nextEF = currentEF + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    final finalEF = max(1.3, nextEF);

    return Sm2Result(
      easiness: finalEF,
      repetitions: nextRepetitions,
      interval: nextInterval,
      dueDate: DateTime.now().add(Duration(days: nextInterval)),
    );
  }

  /// Records a user's SRS review, updates vocabulary progress, creates review log,
  /// and awards XP points.
  Future<Vocabulary> recordReview({
    required Vocabulary vocabulary,
    required int quality,
  }) async {
    final sm2 = calculateSM2(
      quality: quality,
      currentEF: vocabulary.easiness,
      currentRepetitions: vocabulary.repetitions,
      currentInterval: vocabulary.interval,
    );

    final isCorrect = quality >= 3;

    final updatedVocab = vocabulary.copyWith(
      easiness: sm2.easiness,
      repetitions: sm2.repetitions,
      interval: sm2.interval,
      dueDate: sm2.dueDate,
      correctCount: vocabulary.correctCount + (isCorrect ? 1 : 0),
      wrongCount: vocabulary.wrongCount + (!isCorrect ? 1 : 0),
    );

    // 1. Update SQLite DB
    await DatabaseService.instance.updateSrsProgress(updatedVocab);

    // 2. Save Historical Review Log
    await DatabaseService.instance.addReviewLog(
      ReviewLog(
        word: updatedVocab.word,
        quality: quality,
        easiness: sm2.easiness,
        interval: sm2.interval,
        createdAt: DateTime.now(),
      ),
    );

    // 3. Award XP points
    final xpReward = quality == 5
        ? AppConstants.xpPerfectScore
        : (isCorrect ? AppConstants.xpGoodScore : AppConstants.xpFailScore);

    if (xpReward > 0) {
      await DatabaseService.instance.addXp(xpReward);
    }

    return updatedVocab;
  }
}
