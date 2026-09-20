class IpaConverter {
  static const Map<String, String> _arpabetToIpa = {
    // Vowels
    'AA': 'ɑ',
    'AE': 'æ',
    'AH0': 'ə',
    'AH1': 'ʌ',
    'AH2': 'ʌ',
    'AO': 'ɔ',
    'AW': 'aʊ',
    'AY': 'aɪ',
    'EH': 'ɛ',
    'ER0': 'ər',
    'ER1': 'ɜːr',
    'ER2': 'ɜːr',
    'EY': 'eɪ',
    'IH': 'ɪ',
    'IY': 'i',
    'OW': 'oʊ',
    'OY': 'ɔɪ',
    'UH': 'ʊ',
    'UW': 'u',

    // Consonants
    'B': 'b',
    'CH': 'tʃ',
    'D': 'd',
    'DH': 'ð',
    'F': 'f',
    'G': 'ɡ',
    'HH': 'h',
    'JH': 'dʒ',
    'K': 'k',
    'L': 'l',
    'M': 'm',
    'N': 'n',
    'NG': 'ŋ',
    'P': 'p',
    'R': 'ɹ',
    'S': 's',
    'SH': 'ʃ',
    'T': 't',
    'TH': 'θ',
    'V': 'v',
    'W': 'w',
    'Y': 'j',
    'Z': 'z',
    'ZH': 'ʒ',
  };

  static const Set<String> _vowelBases = {
    'AA', 'AE', 'AH', 'AO', 'AW', 'AY', 'EH', 'ER', 'EY', 'IH', 'IY', 'OW', 'OY', 'UH', 'UW'
  };

  /// Converts CMU Dict / Datamuse Arpabet format (e.g., "S T AH1 D IY0") into standard IPA ("/ˈstʌdi/").
  static String arpabetToIpa(String arpabet) {
    final rawTokens = arpabet.trim().split(RegExp(r'\s+'));
    if (rawTokens.isEmpty || arpabet.trim().isEmpty) return '';

    final tokens = rawTokens.where((t) => t.isNotEmpty).toList();
    final result = StringBuffer('/');

    var onsetBuffer = StringBuffer();

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i].toUpperCase();
      final base = token.replaceAll(RegExp(r'\d'), '');
      final isVowel = _vowelBases.contains(base);

      if (!isVowel) {
        final ipaConsonant = _arpabetToIpa[token] ?? _arpabetToIpa[base] ?? base.toLowerCase();
        onsetBuffer.write(ipaConsonant);
      } else {
        // It's a vowel! Check stress
        final isPrimary = token.endsWith('1');
        final isSecondary = token.endsWith('2');

        if (isPrimary) {
          result.write('ˈ');
        } else if (isSecondary) {
          result.write('ˌ');
        }

        // Flush preceding consonants for this syllable onset
        result.write(onsetBuffer.toString());
        onsetBuffer.clear();

        final ipaVowel = _arpabetToIpa[token] ?? _arpabetToIpa[base] ?? base.toLowerCase();
        result.write(ipaVowel);
      }
    }

    // Flush any remaining coda consonants
    if (onsetBuffer.isNotEmpty) {
      result.write(onsetBuffer.toString());
    }

    result.write('/');
    return result.toString();
  }

  /// Extracts UK and US IPA from Wiktionary plain text extract.
  static ({String? uk, String? us, String? general}) extractIpaFromWiktionary(String text) {
    String? ukIpa;
    String? usIpa;
    String? generalIpa;

    // Pattern for RP / UK
    final ukRegex = RegExp(
      r'(?:Received\s+Pronunciation|UK|Standard\s+Southern\s+British)[^\n\/]*IPA(?:(?:\(key\))?):\s*\/([^\/\n]+)\/',
      caseSensitive: false,
    );
    final ukMatch = ukRegex.firstMatch(text);
    if (ukMatch != null) {
      ukIpa = '/${ukMatch.group(1)!.trim()}/';
    }

    // Pattern for US / General American
    final usRegex = RegExp(
      r'(?:General\s+American|US)[^\n\/]*IPA(?:(?:\(key\))?):\s*\/([^\/\n]+)\/',
      caseSensitive: false,
    );
    final usMatch = usRegex.firstMatch(text);
    if (usMatch != null) {
      usIpa = '/${usMatch.group(1)!.trim()}/';
    }

    // Pattern for generic IPA
    final genRegex = RegExp(
      r'IPA(?:(?:\(key\))?):\s*\/([^\/\n]+)\/',
      caseSensitive: false,
    );
    final genMatch = genRegex.firstMatch(text);
    if (genMatch != null) {
      generalIpa = '/${genMatch.group(1)!.trim()}/';
    }

    return (
      uk: ukIpa ?? generalIpa,
      us: usIpa ?? generalIpa,
      general: generalIpa ?? ukIpa ?? usIpa,
    );
  }
}
