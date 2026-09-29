import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/lemmatizer.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../models/grammar_match.dart';
import '../../../models/vocabulary.dart';
import '../../../services/grammar_service.dart';
import '../../../widgets/audio_button.dart';
import '../../../widgets/cefr_badge.dart';
import 'srs_rating_bar.dart';

class PracticeCard extends StatefulWidget {
  final Vocabulary vocabulary;
  final int currentIndex;
  final int totalWords;
  final String topicName;
  final Function(int quality, String? newSentence) onRecordReview;
  final VoidCallback onSkip;

  const PracticeCard({
    super.key,
    required this.vocabulary,
    required this.currentIndex,
    required this.totalWords,
    required this.topicName,
    required this.onRecordReview,
    required this.onSkip,
  });

  @override
  State<PracticeCard> createState() => _PracticeCardState();
}

class _PracticeCardState extends State<PracticeCard> {
  final TextEditingController _sentenceController = TextEditingController();
  final FocusNode _cardFocusNode = FocusNode();
  final FocusNode _sentenceFocusNode = FocusNode();
  bool _isValidWord = false;
  bool _isCheckingGrammar = false;
  bool _showRatingBar = false;
  List<GrammarMatch> _grammarMatches = [];

  @override
  void initState() {
    super.initState();
    _sentenceController.text = widget.vocabulary.userExample ?? '';
    _validateWord(_sentenceController.text);
    // Focus thẻ để bắt phím tắt ngay khi hiển thị
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cardFocusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant PracticeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vocabulary.id != widget.vocabulary.id) {
      _sentenceController.text = widget.vocabulary.userExample ?? '';
      _showRatingBar = false;
      _grammarMatches = [];
      _validateWord(_sentenceController.text);
      // Re-focus khi chuyển sang thẻ mới
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _cardFocusNode.requestFocus();
      });
    }
  }

  void _validateWord(String text) {
    final lower = text.toLowerCase();
    final cleanWord = widget.vocabulary.word.toLowerCase().trim();
    final lemma = Lemmatizer.lemmatize(cleanWord);

    final contains = lower.contains(cleanWord) || lower.contains(lemma);
    setState(() {
      _isValidWord = contains;
    });
  }

  Future<void> _checkGrammar() async {
    final text = _sentenceController.text.trim();
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

  void _submitSentenceAndRate(int quality) {
    final sentence = _sentenceController.text.trim();
    widget.onRecordReview(quality, sentence.isNotEmpty ? sentence : null);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // Nếu ô nhập câu đang focus thì chỉ xử lý Enter
    if (_sentenceFocusNode.hasFocus) {
      if (event.logicalKey == LogicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.isShiftPressed) {
        // Enter: nộp câu và hiện rating hoặc chọn mức Tốt nếu đang ở rating bar
        if (!_showRatingBar) {
          setState(() => _showRatingBar = true);
        }
      }
      return;
    }

    final key = event.logicalKey;

    // Space: lật thẻ (hiện rating bar)
    if (key == LogicalKeyboardKey.space) {
      if (!_showRatingBar) {
        setState(() => _showRatingBar = true);
      }
      return;
    }

    // Phím số để chọn điểm (chỉ khi đang ở chế độ rating)
    if (_showRatingBar) {
      if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
        _submitSentenceAndRate(0); // Chưa nhớ
      } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
        _submitSentenceAndRate(3); // Khó
      } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
        _submitSentenceAndRate(4); // Tốt
      } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
        _submitSentenceAndRate(5); // Rất dễ
      }
    }
  }

  @override
  void dispose() {
    _sentenceController.dispose();
    _cardFocusNode.dispose();
    _sentenceFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = widget.vocabulary;

    return KeyboardListener(
      focusNode: _cardFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Card(
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
                  Row(
                    children: [
                      Icon(Icons.folder_outlined, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Chủ đề: ${widget.topicName}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
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

              const SizedBox(height: 16),

              // Word, CEFR, Part of Speech
              Row(
                children: [
                  Text(
                    v.word,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (v.cefrLevel != null && v.cefrLevel!.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    CefrBadge(level: v.cefrLevel!),
                  ],
                  if (v.partOfSpeech.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        v.partOfSpeech,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 10),

              // UK & US Audio
              Wrap(
                spacing: 8,
                children: [
                  AudioButton(
                    label: 'UK',
                    phonetic: v.phoneticUk,
                    audioUrl: v.audioUrlUk,
                    color: theme.colorScheme.primary,
                  ),
                  AudioButton(
                    label: 'US',
                    phonetic: v.phoneticUs,
                    audioUrl: v.audioUrlUs,
                    color: theme.colorScheme.tertiary,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Official definition
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface, height: 1.4),
                  children: [
                    const TextSpan(
                      text: 'Định nghĩa: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '"${v.definition}"'),
                  ],
                ),
              ),

              // Synonyms & Antonyms if available
              if (v.synonyms != null && v.synonyms!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Đồng nghĩa: ${v.synonyms}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              const Divider(height: 28),

              // User Example input
              Text(
                'Viết câu ví dụ mới của bạn chứa từ "${v.word}":',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _sentenceController,
                focusNode: _sentenceFocusNode,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Nhập câu tiếng Anh có chứa từ "${v.word}"...',
                ),
                onChanged: _validateWord,
              ),
              const SizedBox(height: 8),

              // Live validation & Grammar checker
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
                          ? '✓ Từ "${v.word}" đã xuất hiện trong câu của bạn.'
                          : 'Câu cần chứa từ "${v.word}" (hoặc dạng chia thì).',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isValidWord ? Colors.green : theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isCheckingGrammar ? null : _checkGrammar,
                    icon: _isCheckingGrammar
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.spellcheck, size: 16),
                    label: const Text('Kiểm tra ngữ pháp', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),

              if (_grammarMatches.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LanguageTool gợi ý sửa lỗi (${_grammarMatches.length}):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ..._grammarMatches.map((m) {
                        return Text(
                          '• ${m.message} ${m.replacements.isNotEmpty ? '(Nên đổi: "${m.replacements.first}")' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Action Buttons or SRS Rating Bar
              if (!_showRatingBar) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.onSkip,
                      icon: const Icon(Icons.skip_next, size: 16),
                      label: const Text('Bỏ qua / Chưa nhớ'),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() => _showRatingBar = true);
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Đã nhớ từ & Chấm điểm'),
                    ),
                  ],
                ),
                if (PlatformUtils.isDesktop) ...[
                  const SizedBox(height: 8),
                  // Keyboard hint khi chưa lật thẻ
                  Center(
                    child: Text(
                      '[ Space ] — Lật thẻ & chấm điểm',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.outlineVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ] else ...[
                SrsRatingBar(
                  onRatingSelected: (quality) {
                    _submitSentenceAndRate(quality);
                  },
                ),
                if (PlatformUtils.isDesktop) ...[
                  const SizedBox(height: 8),
                  // Keyboard hint khi đang chọn điểm
                  Center(
                    child: Text(
                      '[ 1 ] Chưa nhớ  [ 2 ] Khó  [ 3 ] Tốt  [ 4 ] Rất dễ',
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
      ),
    );
  }
}
