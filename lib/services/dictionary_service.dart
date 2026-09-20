import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/api_endpoints.dart';
import '../core/utils/cefr_classifier.dart';
import '../core/utils/ipa_converter.dart';
import '../core/utils/lemmatizer.dart';
import '../models/dictionary_entry.dart';
import 'translation_service.dart';

class DictionaryService {
  static final DictionaryService instance = DictionaryService._internal();
  DictionaryService._internal();

  final Map<String, DictionaryEntry> _cache = {};

  /// Looks up a word from online dictionary with lemmatization, dual UK/US audio,
  /// genuine IPA phonetics, CEFR level classification, and Vietnamese translation.
  Future<DictionaryEntry?> lookupWord(String word) async {
    final clean = word.trim().toLowerCase();
    if (clean.isEmpty) return null;

    final lemma = Lemmatizer.lemmatize(clean);

    if (_cache.containsKey(lemma)) {
      return _cache[lemma];
    }
    if (_cache.containsKey(clean)) {
      return _cache[clean];
    }

    // 1. Try Free Dictionary API with a short timeout (2.5s)
    try {
      final uri = Uri.parse('${ApiEndpoints.freeDictionaryBase}/${Uri.encodeComponent(lemma)}');
      final response = await http.get(uri).timeout(const Duration(milliseconds: 2500));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final entry = await _parseFreeDictionaryEntry(lemma, data);
        _cache[lemma] = entry;
        return entry;
      }
    } catch (e) {
      debugPrint('[DictionaryService] FreeDictionary unavailable/timed out for $lemma: $e');
    }

    // 2. Multi-tier Fallback: Wiktionary API (for true IPA) + Datamuse API (for definitions & synonyms)
    try {
      final entry = await _lookupWiktionaryAndDatamuse(clean, lemma);
      if (entry != null) {
        _cache[lemma] = entry;
        return entry;
      }
    } catch (e) {
      debugPrint('[DictionaryService] Wiktionary/Datamuse lookup failed: $e');
    }

    // 3. Last-resort Fallback
    final fallback = await _buildFallbackEntry(clean);
    _cache[clean] = fallback;
    return fallback;
  }

  /// Looks up entry from Wiktionary & Datamuse
  Future<DictionaryEntry?> _lookupWiktionaryAndDatamuse(String originalWord, String lemma) async {
    final queryWord = lemma.isNotEmpty ? lemma : originalWord;

    final wikFuture = http.get(Uri.parse(ApiEndpoints.wiktionaryExtract(queryWord)))
        .timeout(const Duration(seconds: 4))
        .catchError((_) => http.Response('{}', 500));

    final dmFuture = http.get(Uri.parse(ApiEndpoints.datamuseWord(queryWord)))
        .timeout(const Duration(seconds: 4))
        .catchError((_) => http.Response('[]', 500));

    final results = await Future.wait([wikFuture, dmFuture]);
    final wikRes = results[0];
    final dmRes = results[1];

    String? ukIpa;
    String? usIpa;
    String? arpabetIpa;

    // A. Parse Wiktionary extract for IPA
    if (wikRes.statusCode == 200) {
      try {
        final wikData = jsonDecode(wikRes.body);
        final pages = wikData['query']?['pages'] as Map<String, dynamic>? ?? {};
        if (pages.isNotEmpty) {
          final firstPage = pages.values.first as Map<String, dynamic>;
          final extract = firstPage['extract']?.toString() ?? '';
          if (extract.isNotEmpty) {
            final parsedIpa = IpaConverter.extractIpaFromWiktionary(extract);
            ukIpa = parsedIpa.uk;
            usIpa = parsedIpa.us;
          }
        }
      } catch (e) {
        debugPrint('[DictionaryService] Error parsing Wiktionary extract: $e');
      }
    }

    // B. Parse Datamuse for definitions, tags (Arpabet pron, part of speech), synonyms
    final meaningsList = <DictMeaning>[];
    final allSynonyms = <String>{};

    if (dmRes.statusCode == 200) {
      try {
        final dmList = jsonDecode(dmRes.body) as List<dynamic>? ?? [];
        if (dmList.isNotEmpty) {
          final topEntry = dmList[0] as Map<String, dynamic>;
          final tags = (topEntry['tags'] as List<dynamic>? ?? []).cast<String>();

          // Arpabet pronunciation
          final pronTag = tags.firstWhere((t) => t.startsWith('pron:'), orElse: () => '');
          if (pronTag.isNotEmpty) {
            final arpabet = pronTag.replaceFirst('pron:', '').trim();
            arpabetIpa = IpaConverter.arpabetToIpa(arpabet);
          }

          // Parse definitions
          final rawDefs = (topEntry['defs'] as List<dynamic>? ?? []).cast<String>();
          final posGroup = <String, List<DictDefinition>>{};

          for (final raw in rawDefs) {
            final parts = raw.split('\t');
            var pos = 'general';
            var defText = raw;
            if (parts.length >= 2) {
              pos = _expandPos(parts[0].trim());
              defText = parts[1].trim();
            }

            posGroup.putIfAbsent(pos, () => []).add(
              DictDefinition(definition: defText),
            );
          }

          posGroup.forEach((pos, defs) {
            meaningsList.add(DictMeaning(
              partOfSpeech: pos,
              definitions: defs.take(4).toList(),
            ));
          });

          // Synonyms from related words in datamuse
          for (var i = 1; i < dmList.length && allSynonyms.length < 8; i++) {
            final related = dmList[i]['word']?.toString();
            if (related != null && related != queryWord && !related.contains(' ')) {
              allSynonyms.add(related);
            }
          }
        }
      } catch (e) {
        debugPrint('[DictionaryService] Error parsing Datamuse: $e');
      }
    }

    // Combine IPA
    if (ukIpa == null || ukIpa.isEmpty) {
      ukIpa = usIpa ?? arpabetIpa ?? '';
    }
    if (usIpa == null || usIpa.isEmpty) {
      usIpa = ukIpa.isNotEmpty ? ukIpa : (arpabetIpa ?? '');
    }

    // Ensure we don't return an empty entry
    final viMeaning = await TranslationService.instance.translate(queryWord);
    final cefr = CefrClassifier.classify(queryWord);

    if (meaningsList.isEmpty) {
      meaningsList.add(DictMeaning(
        partOfSpeech: 'vocabulary',
        definitions: [
          DictDefinition(
            definition: 'Từ vựng tiếng Anh "$queryWord"',
            vietnameseTranslation: viMeaning,
          ),
        ],
      ));
    } else {
      // Translate top definitions asynchronously
      for (var i = 0; i < meaningsList.length && i < 2; i++) {
        final meaning = meaningsList[i];
        for (var j = 0; j < meaning.definitions.length && j < 2; j++) {
          final d = meaning.definitions[j];
          final trans = await TranslationService.instance.translate(d.definition);
          meaning.definitions[j] = d.copyWith(vietnameseTranslation: trans);
        }
      }
    }

    return DictionaryEntry(
      word: queryWord,
      phonetic: usIpa.isNotEmpty ? usIpa : ukIpa,
      phoneticUk: ukIpa,
      audioUrlUk: ApiEndpoints.googleTtsUk(queryWord),
      phoneticUs: usIpa,
      audioUrlUs: ApiEndpoints.googleTtsUs(queryWord),
      vietnameseMeaning: viMeaning,
      cefrLevel: cefr,
      synonyms: allSynonyms.join(', '),
      antonyms: '',
      meanings: meaningsList,
    );
  }

  String _expandPos(String code) {
    switch (code.toLowerCase()) {
      case 'n':
        return 'noun';
      case 'v':
        return 'verb';
      case 'adj':
        return 'adjective';
      case 'adv':
        return 'adverb';
      case 'u':
        return 'interjection';
      default:
        return code;
    }
  }

  Future<DictionaryEntry> _parseFreeDictionaryEntry(String word, dynamic data) async {
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
      phonetic: '',
      phoneticUk: '',
      audioUrlUk: ApiEndpoints.googleTtsUk(word),
      phoneticUs: '',
      audioUrlUs: ApiEndpoints.googleTtsUs(word),
      vietnameseMeaning: vi,
      cefrLevel: CefrClassifier.classify(word),
      meanings: [
        DictMeaning(
          partOfSpeech: 'vocabulary',
          definitions: [
            DictDefinition(
              definition: 'Từ vựng tiếng Anh: "$word"',
              vietnameseTranslation: vi,
            ),
          ],
        ),
      ],
    );
  }
}
