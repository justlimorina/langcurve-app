import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/api_endpoints.dart';
import '../models/grammar_match.dart';

class GrammarService {
  static final GrammarService instance = GrammarService._internal();
  GrammarService._internal();

  /// Checks English text for grammatical and spelling issues via LanguageTool
  Future<List<GrammarMatch>> checkGrammar(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return [];

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.languageToolCheck),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'text': clean,
          'language': 'en-US',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['matches'] is List) {
          return (data['matches'] as List)
              .map((m) => GrammarMatch.fromMap(m as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[GrammarService] LanguageTool check failed: $e');
    }

    return [];
  }
}
