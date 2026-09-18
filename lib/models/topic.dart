class Topic {
  final int? id;
  final String name;
  final String? description;
  final int wordCount;
  final DateTime createdAt;

  Topic({
    this.id,
    required this.name,
    this.description,
    this.wordCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      wordCount: (map['word_count'] ?? map['wordCount'] ?? 0) as int,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Topic copyWith({
    int? id,
    String? name,
    String? description,
    int? wordCount,
    DateTime? createdAt,
  }) {
    return Topic(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      wordCount: wordCount ?? this.wordCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
