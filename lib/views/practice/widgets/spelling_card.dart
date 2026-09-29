import 'package:flutter/material.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../models/vocabulary.dart';
import '../../../widgets/audio_button.dart';
import '../../../widgets/cefr_badge.dart';

class SpellingCard extends StatefulWidget {
  final Vocabulary vocabulary;
  final int currentIndex;
  final int totalWords;
  final String topicName;
  final Function(int quality, String? newSentence) onRecordReview;
  final VoidCallback onSkip;

  const SpellingCard({
    super.key,
    required this.vocabulary,
    required this.currentIndex,
    required this.totalWords,
    required this.topicName,
    required this.onRecordReview,
    required this.onSkip,
  });

  @override
  State<SpellingCard> createState() => _SpellingCardState();
}

class _SpellingCardState extends State<SpellingCard> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _resetState();
    if (PlatformUtils.isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _inputFocusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant SpellingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vocabulary.id != widget.vocabulary.id) {
      _resetState();
      if (PlatformUtils.isDesktop) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _inputFocusNode.requestFocus();
        });
      }
    }
  }

  void _resetState() {
    _inputController.clear();
    _isAnswered = false;
    _isCorrect = false;
    _showHint = false;
  }

  void _checkSpelling() {
    final typed = _inputController.text.trim().toLowerCase();
    if (typed.isEmpty) return;

    final actual = widget.vocabulary.word.trim().toLowerCase();
    final correct = typed == actual;

    FocusScope.of(context).unfocus();
    setState(() {
      _isAnswered = true;
      _isCorrect = correct;
    });
  }

  void _nextWord() {
    // Correct gives quality 5 (Easy), Wrong gives quality 0 (Again)
    widget.onRecordReview(_isCorrect ? 5 : 0, null);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = widget.vocabulary;
    final wordLength = v.word.trim().length;
    final firstChar = v.word.trim().isNotEmpty ? v.word.trim()[0].toUpperCase() : '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note, size: 16, color: theme.colorScheme.onTertiaryContainer),
                      const SizedBox(width: 6),
                      Text(
                        'Gõ chính tả • ${widget.topicName}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Từ số ${widget.currentIndex + 1} / ${widget.totalWords}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Audio & Hints Area
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Prominent Audio prompt
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AudioButton(
                        label: 'UK',
                        phonetic: v.phoneticUk,
                        audioUrl: v.audioUrlUk,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      AudioButton(
                        label: 'US',
                        phonetic: v.phoneticUs,
                        audioUrl: v.audioUrlUs,
                        color: theme.colorScheme.tertiary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nghe phát âm và gõ lại từ vựng:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$wordLength ký tự',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (v.cefrLevel != null && v.cefrLevel!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            CefrBadge(level: v.cefrLevel!),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Definition hint
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Gợi ý nghĩa (${v.partOfSpeech.isNotEmpty ? v.partOfSpeech : "từ vựng"}):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      if (!_isAnswered && !_showHint)
                        TextButton(
                          onPressed: () => setState(() => _showHint = true),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Hiện chữ cái đầu', style: TextStyle(fontSize: 11)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    v.definition.isNotEmpty ? v.definition : 'Hãy nghe phát âm và hoàn thiện từ vựng.',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (_showHint && !_isAnswered) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Gợi ý: Bắt đầu bằng chữ "$firstChar..."',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Input field
            if (!_isAnswered) ...[
              TextField(
                controller: _inputController,
                focusNode: _inputFocusNode,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                decoration: InputDecoration(
                  hintText: 'Nhập từ tiếng Anh chính xác...',
                  prefixIcon: const Icon(Icons.keyboard),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: 'Kiểm tra',
                    onPressed: _checkSpelling,
                  ),
                ),
                onSubmitted: (_) => _checkSpelling(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onSkip,
                    icon: const Icon(Icons.skip_next, size: 16),
                    label: const Text('Bỏ qua / Chưa nhớ'),
                  ),
                  FilledButton.icon(
                    onPressed: _checkSpelling,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Kiểm tra chính tả'),
                  ),
                ],
              ),
              if (PlatformUtils.isDesktop) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '[ Enter ] — Kiểm tra đáp án',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.outlineVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ] else ...[
              // Result display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isCorrect ? Colors.green.shade300 : Colors.red.shade300,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isCorrect ? Icons.check_circle : Icons.cancel,
                          color: _isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isCorrect ? 'Chính xác! (+15 XP)' : 'Chưa chính xác!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _isCorrect ? Colors.green.shade900 : Colors.red.shade900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Từ chuẩn: "${v.word}"',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _isCorrect ? Colors.green.shade900 : Colors.red.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!_isCorrect) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Bạn đã nhập: "${_inputController.text.trim()}"',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _nextWord,
                        style: FilledButton.styleFrom(
                          backgroundColor: _isCorrect ? Colors.green.shade700 : theme.colorScheme.primary,
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Tiếp tục'),
                      ),
                    ),
                  ],
                ),
              ),
              if (PlatformUtils.isDesktop) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '[ Enter / Space ] — Tiếp tục từ tiếp theo',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.outlineVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
