import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_endpoints.dart';

class TranslationService {
  static final TranslationService instance = TranslationService._internal();
  TranslationService._internal();

  final Map<String, String> _cache = {};

  /// Translates English text to Vietnamese
  Future<String?> translate(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return null;

    if (_cache.containsKey(clean)) {
      return _cache[clean];
    }

    // 1. Google Translate API (Primary, fast, high quota)
    try {
      final uri = Uri.parse(
        '${ApiEndpoints.googleTranslateBase}&q=${Uri.encodeComponent(clean)}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty && data[0] is List) {
          final buffer = StringBuffer();
          for (final item in data[0]) {
            if (item is List && item.isNotEmpty && item[0] != null) {
              buffer.write(item[0]);
            }
          }
          final translated = buffer.toString().trim();
          if (translated.isNotEmpty && !translated.contains('MYMEMORY WARNING')) {
            _cache[clean] = translated;
            return translated;
          }
        }
      }
    } catch (e) {
      debugPrint('[TranslationService] Google Translate failed, fallback to MyMemory: $e');
    }

    // 2. MyMemory Translation API (Fallback)
    try {
      final uri = Uri.parse(
        '${ApiEndpoints.myMemoryTranslateBase}?q=${Uri.encodeComponent(clean)}&langpair=en|vi&de=langcurve_app@outlook.com',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['responseData'] != null && data['responseData']['translatedText'] != null) {
          final translated = data['responseData']['translatedText'].toString().trim();
          if (translated.isNotEmpty && !translated.contains('MYMEMORY WARNING')) {
            _cache[clean] = translated;
            return translated;
          }
        }
      }
    } catch (e) {
      debugPrint('[TranslationService] MyMemory failed: $e');
    }

    return null;
  }
}
