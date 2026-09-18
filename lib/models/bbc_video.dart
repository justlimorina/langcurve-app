class BbcVideo {
  final String id;
  final String title;
  final String desc;
  final String? publishedAt;

  BbcVideo({
    required this.id,
    required this.title,
    required this.desc,
    this.publishedAt,
  });

  String get thumbnailUrl => 'https://img.youtube.com/vi/$id/mqdefault.jpg';
  String get videoUrl => 'https://www.youtube.com/watch?v=$id';

  factory BbcVideo.fromMap(Map<String, dynamic> map) {
    return BbcVideo(
      id: map['id'] as String,
      title: map['title'] as String,
      desc: (map['desc'] ?? '') as String,
      publishedAt: map['publishedAt'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'desc': desc,
      if (publishedAt != null) 'publishedAt': publishedAt,
    };
  }
}
