import 'package:flutter/material.dart';
import '../../../core/utils/lemmatizer.dart';
import '../../../models/grammar_match.dart';
import '../../../services/grammar_service.dart';

class EditExampleDialog extends StatefulWidget {
  final int vocabId;
  final String word;
  final String? initialExample;
  final Function(String newExample) onSave;

  const EditExampleDialog({
    super.key,
    required this.vocabId,
    required this.word,
    this.initialExample,
    required this.onSave,
  });

  @override
  State<EditExampleDialog> createState() => _EditExampleDialogState();
}

class _EditExampleDialogState extends State<EditExampleDialog> {
  late final TextEditingController _controller;
  bool _isValidWord = false;
  bool _isCheckingGrammar = false;
  List<GrammarMatch> _grammarMatches = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialExample ?? '');
    _validateWord(_controller.text);
  }

  void _validateWord(String text) {
    final lower = text.toLowerCase();
    final cleanWord = widget.word.toLowerCase().trim();
    final lemma = Lemmatizer.lemmatize(cleanWord);

    final contains = lower.contains(cleanWord) || lower.contains(lemma);
    setState(() {
      _isValidWord = contains;
    });
  }

  Future<void> _checkGrammar() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isCheckingGrammar = true);
    final matches = await GrammarService.instance.checkGrammar(text);
    if (mounted) {
      setState(() {
        _grammarMatches = matches;
        _isCheckingGrammar = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.edit_note, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Ví dụ của bạn'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                ),
                children: [
                  const TextSpan(text: 'Đặt câu chứa từ: '),
                  TextSpan(
                    text: widget.word,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Viết câu ví dụ tiếng Anh của bạn *',
                hintText: 'Nhập một câu hoàn chỉnh có chứa từ vựng trên...',
              ),
              onChanged: _validateWord,
            ),
            const SizedBox(height: 8),

            // Live validation indicator
            Row(
              children: [
                Icon(
                  _isValidWord ? Icons.check_circle : Icons.info_outline,
                  size: 16,
                  color: _isValidWord ? Colors.green : theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _isValidWord
                        ? '✓ Hợp lệ: Từ vựng đã xuất hiện trong câu của bạn.'
                        : 'Hãy đảm bảo câu có chứa từ "${widget.word}" (hoặc dạng chia).',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isValidWord ? Colors.green : theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Grammar Checker button
            OutlinedButton.icon(
              onPressed: _isCheckingGrammar ? null : _checkGrammar,
              icon: _isCheckingGrammar
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.spellcheck, size: 16),
              label: const Text('Kiểm tra ngữ pháp (LanguageTool)'),
            ),

            if (_grammarMatches.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gợi ý sửa lỗi (${_grammarMatches.length}):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._grammarMatches.map((m) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${m.message} ${m.replacements.isNotEmpty ? '(Nên đổi: "${m.replacements.first}")' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) {
              widget.onSave(text);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Lưu câu ví dụ'),
        ),
      ],
    );
  }
}
