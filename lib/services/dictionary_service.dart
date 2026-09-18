import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/api_endpoints.dart';
import '../core/utils/cefr_classifier.dart';
import '../core/utils/lemmatizer.dart';
import '../models/dictionary_entry.dart';
import 'translation_service.dart';

class DictionaryService {
  static final DictionaryService instance = DictionaryService._internal();
  DictionaryService._internal();

  final Map<String, DictionaryEntry> _cache = {};

  /// Looks up a word from online dictionary with lemmatization, dual UK/US audio,
  /// CEFR level classification, and Vietnamese translation.
  Future<DictionaryEntry?> lookupWord(String word) async {
    final clean = word.trim().toLowerCase();
    if (clean.isEmpty) return null;

    final lemma = Lemmatizer.lemmatize(clean);

    if (_cache.containsKey(lemma)) {
      return _cache[lemma];
    }

    try {
      final uri = Uri.parse('${ApiEndpoints.freeDictionaryBase}/${Uri.encodeComponent(lemma)}');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        // If lemma fails, try the original word
        if (lemma != clean) {
          final altUri = Uri.parse('${ApiEndpoints.freeDictionaryBase}/${Uri.encodeComponent(clean)}');
          final altResponse = await http.get(altUri).timeout(const Duration(seconds: 8));
          if (altResponse.statusCode == 200) {
            return _parseEntry(clean, jsonDecode(altResponse.body));
          }
        }
        // Fallback: build minimal entry with Google TTS and Translation
        return await _buildFallbackEntry(lemma);
      }

      final data = jsonDecode(response.body);
      final entry = await _parseEntry(lemma, data);
      _cache[lemma] = entry;
      return entry;
    } catch (e) {
      debugPrint('[DictionaryService] Lookup failed for $lemma: $e');
      return await _buildFallbackEntry(lemma);
    }
  }

  Future<DictionaryEntry> _parseEntry(String word, dynamic data) async {
    if (data is! List || data.isEmpty) {
      return await _buildFallbackEntry(word);
    }

    final entryJson = data[0] as Map<String, dynamic>;

    String phonetic = entryJson['phonetic']?.toString() ?? '';
    String phoneticUk = '';
    String audioUrlUk = '';
    String phoneticUs = '';
    String audioUrlUs = '';

    final phoneticsList = entryJson['phonetics'] as List<dynamic>? ?? [];

    for (final p in phoneticsList) {
      if (p is Map) {
        final audio = (p['audio']?.toString() ?? '').toLowerCase();
        final text = p['text']?.toString() ?? '';

        if (audio.contains('-uk') || audio.contains('/uk/') || text.toLowerCase().contains('uk')) {
          if (phoneticUk.isEmpty && text.isNotEmpty) phoneticUk = text;
          if (audioUrlUk.isEmpty && audio.isNotEmpty) audioUrlUk = p['audio'].toString();
        } else if (audio.contains('-us') || audio.contains('/us/') || text.toLowerCase().contains('us')) {
          if (phoneticUs.isEmpty && text.isNotEmpty) phoneticUs = text;
          if (audioUrlUs.isEmpty && audio.isNotEmpty) audioUrlUs = p['audio'].toString();
        }
      }
    }

    // Fill missing pronunciations
    for (final p in phoneticsList) {
      if (p is Map) {
        final audio = p['audio']?.toString() ?? '';
        final text = p['text']?.toString() ?? '';

        if (audioUrlUk.isEmpty && audio.isNotEmpty) audioUrlUk = audio;
        if (audioUrlUs.isEmpty && audio.isNotEmpty) audioUrlUs = audio;
        if (phoneticUk.isEmpty && text.isNotEmpty) phoneticUk = text;
        if (phoneticUs.isEmpty && text.isNotEmpty && text != phoneticUk) phoneticUs = text;
      }
    }

    if (phonetic.isEmpty) {
      phonetic = phoneticUk.isNotEmpty ? phoneticUk : phoneticUs;
    }
    if (phoneticUk.isEmpty) phoneticUk = phonetic;
    if (phoneticUs.isEmpty) phoneticUs = phonetic;

    // Fallback to Google TTS if audio is still missing
    if (audioUrlUk.isEmpty) audioUrlUk = ApiEndpoints.googleTtsUk(word);
    if (audioUrlUs.isEmpty) audioUrlUs = ApiEndpoints.googleTtsUs(word);

    // Parse Meanings
    final meaningsList = <DictMeaning>[];
    final allSynonyms = <String>{};
    final allAntonyms = <String>{};

    final rawMeanings = entryJson['meanings'] as List<dynamic>? ?? [];

    for (final m in rawMeanings) {
      if (m is Map) {
        final pos = m['partOfSpeech']?.toString() ?? '';
        final defs = <DictDefinition>[];

        // Synonyms & Antonyms for meaning
        final mSyn = (m['synonyms'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
        final mAnt = (m['antonyms'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
        allSynonyms.addAll(mSyn);
        allAntonyms.addAll(mAnt);

        final rawDefs = m['definitions'] as List<dynamic>? ?? [];
        for (final d in rawDefs) {
          if (d is Map) {
            final defText = d['definition']?.toString() ?? '';
            final example = d['example']?.toString();
            final dSyn = (d['synonyms'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
            final dAnt = (d['antonyms'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
            allSynonyms.addAll(dSyn);
            allAntonyms.addAll(dAnt);

            defs.add(DictDefinition(
              definition: defText,
              example: example,
              synonyms: dSyn,
              antonyms: dAnt,
            ));
          }
        }

        meaningsList.add(DictMeaning(
          partOfSpeech: pos,
          definitions: defs,
          synonyms: mSyn,
          antonyms: mAnt,
        ));
      }
    }

    final cefr = CefrClassifier.classify(word);
    final viMeaning = await TranslationService.instance.translate(word);

    // Translate primary definitions asynchronously
    for (var i = 0; i < meaningsList.length && i < 2; i++) {
      final meaning = meaningsList[i];
      for (var j = 0; j < meaning.definitions.length && j < 2; j++) {
        final d = meaning.definitions[j];
        final trans = await TranslationService.instance.translate(d.definition);
        meaning.definitions[j] = d.copyWith(vietnameseTranslation: trans);
      }
    }

    return DictionaryEntry(
      word: word,
      phonetic: phonetic,
      phoneticUk: phoneticUk,
      audioUrlUk: audioUrlUk,
      phoneticUs: phoneticUs,
      audioUrlUs: audioUrlUs,
      vietnameseMeaning: viMeaning,
      cefrLevel: cefr,
      synonyms: allSynonyms.take(8).join(', '),
      antonyms: allAntonyms.take(8).join(', '),
      meanings: meaningsList,
    );
  }

  Future<DictionaryEntry> _buildFallbackEntry(String word) async {
    final vi = await TranslationService.instance.translate(word);
    return DictionaryEntry(
      word: word,
      phonetic: '/$word/',
      phoneticUk: '/$word/',
      audioUrlUk: ApiEndpoints.googleTtsUk(word),
      phoneticUs: '/$word/',
      audioUrlUs: ApiEndpoints.googleTtsUs(word),
      vietnameseMeaning: vi,
      cefrLevel: CefrClassifier.classify(word),
      meanings: [
        DictMeaning(
          partOfSpeech: 'vocabulary',
          definitions: [
            DictDefinition(
              definition: 'Tra cứu trực tuyến (TTS Fallback).',
              vietnameseTranslation: vi,
            ),
          ],
        ),
      ],
    );
  }
}
