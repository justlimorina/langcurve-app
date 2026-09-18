class UserProfile {
  final int xp;
  final int streakDays;
  final String levelTitle;

  UserProfile({
    this.xp = 0,
    this.streakDays = 1,
    String? levelTitle,
  }) : levelTitle = levelTitle ?? _calculateLevel(xp);

  static String _calculateLevel(int xp) {
    if (xp < 100) return 'Tập sự (Novice)';
    if (xp < 300) return 'Khởi sắc (Apprentice)';
    if (xp < 600) return 'Kiên trì (Dedicated)';
    if (xp < 1000) return 'Thành thạo (Proficient)';
    if (xp < 2000) return 'Bậc thầy (Master)';
    return 'Huyền thoại (Legend)';
  }

  UserProfile copyWith({
    int? xp,
    int? streakDays,
    String? levelTitle,
  }) {
    return UserProfile(
      xp: xp ?? this.xp,
      streakDays: streakDays ?? this.streakDays,
      levelTitle: levelTitle ?? this.levelTitle,
    );
  }
}
