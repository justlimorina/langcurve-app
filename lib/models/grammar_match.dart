class GrammarMatch {
  final String message;
  final String shortMessage;
  final int offset;
  final int length;
  final List<String> replacements;
  final String issueType;

  GrammarMatch({
    required this.message,
    this.shortMessage = '',
    required this.offset,
    required this.length,
    this.replacements = const [],
    this.issueType = '',
  });

  factory GrammarMatch.fromMap(Map<String, dynamic> map) {
    final replacementsList = <String>[];
    if (map['replacements'] is List) {
      for (final r in map['replacements']) {
        if (r is Map && r['value'] != null) {
          replacementsList.add(r['value'].toString());
        }
      }
    }

    return GrammarMatch(
      message: (map['message'] ?? '') as String,
      shortMessage: (map['shortMessage'] ?? '') as String,
      offset: (map['offset'] ?? 0) as int,
      length: (map['length'] ?? 0) as int,
      replacements: replacementsList,
      issueType: map['rule'] != null && map['rule']['issueType'] != null
          ? map['rule']['issueType'].toString()
          : '',
    );
  }
}
