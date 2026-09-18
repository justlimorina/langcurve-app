class AppConstants {
  static const String appName = 'LangCurve';
  static const String appTagline = 'Học từ vựng tiếng Anh theo chủ đề & SuperMemo SM-2';
  
  // Storage Keys
  static const String keyThemeMode = 'langcurve_theme_mode';
  static const String keyFirstRun = 'langcurve_first_run';

  // XP Rewards
  static const int xpPerfectScore = 20; // Rating 5 (Dễ / Perfect)
  static const int xpGoodScore = 10;    // Rating 3-4 (Khá / Tốt)
  static const int xpFailScore = 0;     // Rating < 3 (Chưa nhớ)

  // Default Topics
  static const List<Map<String, String>> defaultTopics = [
    {
      'name': 'Công nghệ thông tin',
      'description': 'Từ vựng chuyên ngành phần mềm, khoa học máy tính và AI.'
    },
    {
      'name': 'Giao tiếp hàng ngày',
      'description': 'Các mẫu câu và từ vựng thông dụng trong đời sống sinh hoạt.'
    },
    {
      'name': 'Học thuật & IELTS',
      'description': 'Từ vựng học thuật cấp độ B2-C1 phục vụ viết luận và thi cử.'
    },
    {
      'name': 'Du lịch & Văn hóa',
      'description': 'Khám phá thế giới, đặt phòng, vé máy bay và ẩm thực.'
    }
  ];
}
