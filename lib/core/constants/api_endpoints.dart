class ApiEndpoints {
  // Free Dictionary API
  static const String freeDictionaryBase = 'https://api.dictionaryapi.dev/api/v2/entries/en';

  // Google Translate API (Free endpoint for English -> Vietnamese)
  static const String googleTranslateBase = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=vi&dt=t';

  // MyMemory Translation API Fallback
  static const String myMemoryTranslateBase = 'https://api.mymemory.translated.net/get';

  // LanguageTool Grammar Checker API
  static const String languageToolCheck = 'https://api.languagetool.org/v2/check';

  // Google Text-To-Speech Fallback Audio URLs
  static String googleTtsUk(String word) =>
      'https://translate.google.com/translate_tts?ie=UTF-8&tl=en-GB&client=tw-ob&q=${Uri.encodeComponent(word)}';
      
  static String googleTtsUs(String word) =>
      'https://translate.google.com/translate_tts?ie=UTF-8&tl=en-US&client=tw-ob&q=${Uri.encodeComponent(word)}';

  // BBC Learning English Official YouTube RSS Feed
  static const String bbcLearningEnglishRss =
      'https://www.youtube.com/feeds/videos.xml?playlist_id=UULFHaHD477h-FeBbVh9Sh7syA';
}
