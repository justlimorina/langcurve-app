class ReviewLog {
  final int? id;
  final String word;
  final int quality;
  final double easiness;
  final int interval;
  final DateTime createdAt;

  ReviewLog({
    this.id,
    required this.word,
    required this.quality,
    required this.easiness,
    required this.interval,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'word': word,
      'quality': quality,
      'easiness': easiness,
      'interval': interval,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReviewLog.fromMap(Map<String, dynamic> map) {
    return ReviewLog(
      id: map['id'] as int?,
      word: map['word'] as String,
      quality: map['quality'] as int,
      easiness: ((map['easiness'] ?? 2.5) as num).toDouble(),
      interval: (map['interval'] ?? 0) as int,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }
}
