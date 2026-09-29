import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../models/vocabulary.dart';
import '../../../widgets/audio_button.dart';
import '../../../widgets/cefr_badge.dart';

class QuizCard extends StatefulWidget {
  final Vocabulary vocabulary;
  final List<Vocabulary> allVocabularies;
  final int currentIndex;
  final int totalWords;
  final String topicName;
  final Function(int quality, String? newSentence) onRecordReview;
  final VoidCallback onSkip;

  const QuizCard({
    super.key,
    required this.vocabulary,
    required this.allVocabularies,
    required this.currentIndex,
    required this.totalWords,
    required this.topicName,
    required this.onRecordReview,
    required this.onSkip,
  });

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  final FocusNode _cardFocusNode = FocusNode();
  late List<String> _options;
  late int _correctOptionIndex;
  int? _selectedOptionIndex;
  bool _isAnswered = false;

  final List<String> _fallbackDistractors = [
    'Khả năng phục hồi nhanh chóng sau biến cố',
    'Sự trùng hợp ngẫu nhiên nhưng mang lại may mắn',
    'Tính cách tỉ mỉ, cẩn thận đến từng chi tiết',
    'Một khoảnh khắc bất ngờ nhận thức ra chân lý',
    'Mô hình chuẩn mực hoặc hệ tư tưởng mẫu',
    'Thực hiện hợp tác chặt chẽ cùng nhau',
    'Phát triển bền vững, thân thiện với môi trường',
  ];

  @override
  void initState() {
    super.initState();
    _setupQuiz();
    if (PlatformUtils.isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _cardFocusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant QuizCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vocabulary.id != widget.vocabulary.id) {
      _setupQuiz();
      if (PlatformUtils.isDesktop) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _cardFocusNode.requestFocus();
        });
      }
    }
  }

  void _setupQuiz() {
    _selectedOptionIndex = null;
    _isAnswered = false;

    final correctAnswer = widget.vocabulary.definition.trim().isNotEmpty
        ? widget.vocabulary.definition.trim()
        : 'Định nghĩa của từ "${widget.vocabulary.word}"';

    // Collect distractors from other vocabularies
    final candidateDistractors = widget.allVocabularies
        .where((v) => v.id != widget.vocabulary.id && v.definition.trim().isNotEmpty)
        .map((v) => v.definition.trim())
        .toSet()
        .toList();

    candidateDistractors.shuffle(Random());

    final distractors = <String>[];
    for (final d in candidateDistractors) {
      if (d != correctAnswer && !distractors.contains(d)) {
        distractors.add(d);
      }
      if (distractors.length == 3) break;
    }

    // Fill with fallback distractors if not enough words in notebook
    var fbIndex = 0;
    while (distractors.length < 3 && fbIndex < _fallbackDistractors.length) {
      final fb = _fallbackDistractors[fbIndex++];
      if (fb != correctAnswer && !distractors.contains(fb)) {
        distractors.add(fb);
      }
    }

    final combined = [correctAnswer, ...distractors]..shuffle(Random());
    _options = combined;
    _correctOptionIndex = _options.indexOf(correctAnswer);
  }

  void _chooseOption(int index) {
    if (_isAnswered) return;

    setState(() {
      _selectedOptionIndex = index;
      _isAnswered = true;
    });
  }

  void _nextQuestion() {
    if (!_isAnswered) return;
    final isCorrect = _selectedOptionIndex == _correctOptionIndex;
    // Correct gives quality 4 (Good), Wrong gives quality 0 (Again)
    widget.onRecordReview(isCorrect ? 4 : 0, null);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (!PlatformUtils.isDesktop || event is! KeyDownEvent) return;

    final key = event.logicalKey;
    if (!_isAnswered) {
      if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
        if (_options.isNotEmpty) _chooseOption(0);
      } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
        if (_options.length > 1) _chooseOption(1);
      } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
        if (_options.length > 2) _chooseOption(2);
      } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
        if (_options.length > 3) _chooseOption(3);
      }
    } else {
      if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
        _nextQuestion();
      }
    }
  }

  @override
  void dispose() {
    _cardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = widget.vocabulary;
    final isCorrect = _selectedOptionIndex == _correctOptionIndex;

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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.quiz, size: 16, color: theme.colorScheme.onPrimaryContainer),
                        const SizedBox(width: 6),
                        Text(
                          'Trắc nghiệm • ${widget.topicName}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Câu ${widget.currentIndex + 1} / ${widget.totalWords}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Word display
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

              // Audio buttons
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

              const SizedBox(height: 20),

              Text(
                'Chọn nghĩa chính xác nhất:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 12),

              // 4 Choices
              ...List.generate(_options.length, (index) {
                final optionText = _options[index];
                final optionLabel = String.fromCharCode(65 + index); // A, B, C, D

                Color? backgroundColor;
                Color? borderColor;
                Color? textColor;
                IconData? statusIcon;

                if (_isAnswered) {
                  if (index == _correctOptionIndex) {
                    backgroundColor = Colors.green.shade50;
                    borderColor = Colors.green.shade600;
                    textColor = Colors.green.shade900;
                    statusIcon = Icons.check_circle;
                  } else if (index == _selectedOptionIndex) {
                    backgroundColor = Colors.red.shade50;
                    borderColor = Colors.red.shade600;
                    textColor = Colors.red.shade900;
                    statusIcon = Icons.cancel;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _isAnswered ? null : () => _chooseOption(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: backgroundColor ?? theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: borderColor ?? theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                          width: (index == _selectedOptionIndex || index == _correctOptionIndex && _isAnswered) ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: borderColor != null
                                  ? borderColor.withValues(alpha: 0.2)
                                  : theme.colorScheme.surfaceContainerHighest,
                            ),
                            child: Center(
                              child: Text(
                                optionLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: textColor ?? theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              optionText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: (index == _selectedOptionIndex || index == _correctOptionIndex && _isAnswered)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: textColor ?? theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (statusIcon != null) ...[
                            const SizedBox(width: 8),
                            Icon(statusIcon, color: borderColor, size: 20),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Feedback and Next Button
              if (_isAnswered) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCorrect ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.info,
                        color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isCorrect
                              ? 'Chính xác! (+10 XP)'
                              : 'Chưa chính xác. Đáp án đúng là: ${_options[_correctOptionIndex]}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isCorrect ? Colors.green.shade900 : Colors.red.shade900,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: _nextQuestion,
                        style: FilledButton.styleFrom(
                          backgroundColor: isCorrect ? Colors.green.shade700 : theme.colorScheme.primary,
                        ),
                        child: const Text('Tiếp tục'),
                      ),
                    ],
                  ),
                ),
                if (PlatformUtils.isDesktop) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '[ Space / Enter ] — Tiếp tục câu tiếp theo',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.outlineVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.onSkip,
                      icon: const Icon(Icons.skip_next, size: 16),
                      label: const Text('Bỏ qua'),
                    ),
                    if (PlatformUtils.isDesktop)
                      Text(
                        '[ 1 ] [ 2 ] [ 3 ] [ 4 ] — Chọn nhanh đáp án',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.outlineVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
