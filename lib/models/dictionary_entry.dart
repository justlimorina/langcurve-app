class DictDefinition {
  final String definition;
  final String? vietnameseTranslation;
  final String? example;
  final List<String> synonyms;
  final List<String> antonyms;

  DictDefinition({
    required this.definition,
    this.vietnameseTranslation,
    this.example,
    this.synonyms = const [],
    this.antonyms = const [],
  });

  DictDefinition copyWith({
    String? definition,
    String? vietnameseTranslation,
    String? example,
    List<String>? synonyms,
    List<String>? antonyms,
  }) {
    return DictDefinition(
      definition: definition ?? this.definition,
      vietnameseTranslation: vietnameseTranslation ?? this.vietnameseTranslation,
      example: example ?? this.example,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
    );
  }
}

class DictMeaning {
  final String partOfSpeech;
  final List<DictDefinition> definitions;
  final List<String> synonyms;
  final List<String> antonyms;

  DictMeaning({
    required this.partOfSpeech,
    required this.definitions,
    this.synonyms = const [],
    this.antonyms = const [],
  });
}

class DictionaryEntry {
  final String word;
  final String phonetic;
  final String phoneticUk;
  final String audioUrlUk;
  final String phoneticUs;
  final String audioUrlUs;
  final String? vietnameseMeaning;
  final String cefrLevel;
  final String synonyms;
  final String antonyms;
  final List<DictMeaning> meanings;

  DictionaryEntry({
    required this.word,
    this.phonetic = '',
    this.phoneticUk = '',
    this.audioUrlUk = '',
    this.phoneticUs = '',
    this.audioUrlUs = '',
    this.vietnameseMeaning,
    this.cefrLevel = 'B1',
    this.synonyms = '',
    this.antonyms = '',
    this.meanings = const [],
  });

  DictionaryEntry copyWith({
    String? word,
    String? phonetic,
    String? phoneticUk,
    String? audioUrlUk,
    String? phoneticUs,
    String? audioUrlUs,
    String? vietnameseMeaning,
    String? cefrLevel,
    String? synonyms,
    String? antonyms,
    List<DictMeaning>? meanings,
  }) {
    return DictionaryEntry(
      word: word ?? this.word,
      phonetic: phonetic ?? this.phonetic,
      phoneticUk: phoneticUk ?? this.phoneticUk,
      audioUrlUk: audioUrlUk ?? this.audioUrlUk,
      phoneticUs: phoneticUs ?? this.phoneticUs,
      audioUrlUs: audioUrlUs ?? this.audioUrlUs,
      vietnameseMeaning: vietnameseMeaning ?? this.vietnameseMeaning,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
      meanings: meanings ?? this.meanings,
    );
  }
}
