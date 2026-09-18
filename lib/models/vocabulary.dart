class Vocabulary {
  final int? id;
  final int topicId;
  final String? topicName;
  final String word;
  final String definition;
  final String partOfSpeech;
  final String? phoneticUk;
  final String? audioUrlUk;
  final String? phoneticUs;
  final String? audioUrlUs;
  final String? userExample;
  final double easiness; // EF in SM-2, default 2.5
  final int interval;    // Interval in days
  final int repetitions; // Consecutive correct repetitions
  final DateTime dueDate;
  final int correctCount;
  final int wrongCount;
  final String? cefrLevel;
  final String? synonyms;
  final String? antonyms;
  final DateTime createdAt;

  Vocabulary({
    this.id,
    required this.topicId,
    this.topicName,
    required this.word,
    this.definition = '',
    this.partOfSpeech = '',
    this.phoneticUk,
    this.audioUrlUk,
    this.phoneticUs,
    this.audioUrlUs,
    this.userExample,
    this.easiness = 2.5,
    this.interval = 0,
    this.repetitions = 0,
    DateTime? dueDate,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.cefrLevel,
    this.synonyms,
    this.antonyms,
    DateTime? createdAt,
  })  : dueDate = dueDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  bool get isDue => dueDate.isBefore(DateTime.now());

  String get countdownText {
    final now = DateTime.now();
    if (isDue) return 'Đến hạn ôn tập';
    final diff = dueDate.difference(now);
    final hours = diff.inHours;
    if (hours < 24) {
      final h = hours <= 0 ? 1 : hours;
      return 'Còn $h giờ';
    }
    final days = diff.inDays;
    return 'Còn ${days <= 0 ? 1 : days} ngày';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'topic_id': topicId,
      'word': word,
      'definition': definition,
      'part_of_speech': partOfSpeech,
      'phonetic_uk': phoneticUk,
      'audio_url_uk': audioUrlUk,
      'phonetic_us': phoneticUs,
      'audio_url_us': audioUrlUs,
      'user_example': userExample,
      'easiness': easiness,
      'interval': interval,
      'repetitions': repetitions,
      'due_date': dueDate.toIso8601String(),
      'correct_count': correctCount,
      'wrong_count': wrongCount,
      'cefr_level': cefrLevel,
      'synonyms': synonyms,
      'antonyms': antonyms,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Vocabulary.fromMap(Map<String, dynamic> map) {
    return Vocabulary(
      id: map['id'] as int?,
      topicId: (map['topic_id'] ?? map['topicId']) as int,
      topicName: map['topic_name'] as String?,
      word: map['word'] as String,
      definition: (map['definition'] ?? '') as String,
      partOfSpeech: (map['part_of_speech'] ?? map['partOfSpeech'] ?? '') as String,
      phoneticUk: (map['phonetic_uk'] ?? map['phoneticUk']) as String?,
      audioUrlUk: (map['audio_url_uk'] ?? map['audioUrlUk']) as String?,
      phoneticUs: (map['phonetic_us'] ?? map['phoneticUs']) as String?,
      audioUrlUs: (map['audio_url_us'] ?? map['audioUrlUs']) as String?,
      userExample: (map['user_example'] ?? map['userExample']) as String?,
      easiness: ((map['easiness'] ?? 2.5) as num).toDouble(),
      interval: (map['interval'] ?? 0) as int,
      repetitions: (map['repetitions'] ?? 0) as int,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'])
          : (map['dueDate'] != null ? DateTime.parse(map['dueDate']) : DateTime.now()),
      correctCount: (map['correct_count'] ?? map['correctCount'] ?? 0) as int,
      wrongCount: (map['wrong_count'] ?? map['wrongCount'] ?? 0) as int,
      cefrLevel: (map['cefr_level'] ?? map['cefrLevel']) as String?,
      synonyms: map['synonyms'] as String?,
      antonyms: map['antonyms'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Vocabulary copyWith({
    int? id,
    int? topicId,
    String? topicName,
    String? word,
    String? definition,
    String? partOfSpeech,
    String? phoneticUk,
    String? audioUrlUk,
    String? phoneticUs,
    String? audioUrlUs,
    String? userExample,
    double? easiness,
    int? interval,
    int? repetitions,
    DateTime? dueDate,
    int? correctCount,
    int? wrongCount,
    String? cefrLevel,
    String? synonyms,
    String? antonyms,
    DateTime? createdAt,
  }) {
    return Vocabulary(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
      word: word ?? this.word,
      definition: definition ?? this.definition,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      phoneticUk: phoneticUk ?? this.phoneticUk,
      audioUrlUk: audioUrlUk ?? this.audioUrlUk,
      phoneticUs: phoneticUs ?? this.phoneticUs,
      audioUrlUs: audioUrlUs ?? this.audioUrlUs,
      userExample: userExample ?? this.userExample,
      easiness: easiness ?? this.easiness,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      dueDate: dueDate ?? this.dueDate,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
