import 'package:flutter/material.dart';
import '../../../models/vocabulary.dart';
import '../../../widgets/audio_button.dart';
import '../../../widgets/cefr_badge.dart';
import 'edit_example_dialog.dart';

class VocabCard extends StatelessWidget {
  final Vocabulary vocab;
  final Function(String newExample) onEditExample;
  final VoidCallback onDelete;

  const VocabCard({
    super.key,
    required this.vocab,
    required this.onEditExample,
    required this.onDelete,
  });

  Widget _buildHighlightedExample(BuildContext context, String example, String word) {
    final theme = Theme.of(context);
    final lowerExample = example.toLowerCase();
    final lowerWord = word.toLowerCase();

    final index = lowerExample.indexOf(lowerWord);
    if (index == -1) {
      return Text(
        '"$example"',
        style: TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurface,
        ),
      );
    }

    final before = example.substring(0, index);
    final match = example.substring(index, index + word.length);
    final after = example.substring(index + word.length);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurface,
        ),
        children: [
          const TextSpan(text: '"'),
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.5),
            ),
          ),
          TextSpan(text: after),
          const TextSpan(text: '"'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Word, CEFR, Due tag, Delete icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      vocab.word,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (vocab.cefrLevel != null && vocab.cefrLevel!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      CefrBadge(level: vocab.cefrLevel!),
                    ],
                    if (vocab.partOfSpeech.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          vocab.partOfSpeech,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: vocab.isDue
                            ? theme.colorScheme.errorContainer.withOpacity(0.5)
                            : theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        vocab.countdownText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: vocab.isDue
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: theme.colorScheme.outline,
                      tooltip: 'Xóa từ này',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Xác nhận xóa'),
                            content: Text('Bạn có chắc muốn xóa từ "${vocab.word}" khỏi Notebook?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Hủy'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error,
                                ),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  onDelete();
                                },
                                child: const Text('Xóa'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // UK and US Pronunciations
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                AudioButton(
                  label: 'UK',
                  phonetic: vocab.phoneticUk,
                  audioUrl: vocab.audioUrlUk,
                  color: theme.colorScheme.primary,
                ),
                AudioButton(
                  label: 'US',
                  phonetic: vocab.phoneticUs,
                  audioUrl: vocab.audioUrlUs,
                  color: theme.colorScheme.tertiary,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Definition
            if (vocab.definition.isNotEmpty)
              Text(
                vocab.definition,
                style: const TextStyle(fontSize: 14, height: 1.3),
              ),

            const SizedBox(height: 10),

            // User Example Sentence
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 4,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ví dụ của bạn:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => EditExampleDialog(
                              vocabId: vocab.id!,
                              word: vocab.word,
                              initialExample: vocab.userExample,
                              onSave: onEditExample,
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              vocab.userExample != null && vocab.userExample!.isNotEmpty
                                  ? 'Chỉnh sửa'
                                  : 'Thêm ví dụ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (vocab.userExample != null && vocab.userExample!.isNotEmpty)
                    _buildHighlightedExample(context, vocab.userExample!, vocab.word)
                  else
                    Text(
                      '(Chưa có câu ví dụ minh họa)',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
