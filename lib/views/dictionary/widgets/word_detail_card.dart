import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/dictionary_entry.dart';
import '../../../providers/app_state_provider.dart';
import '../../../widgets/audio_button.dart';
import '../../../widgets/cefr_badge.dart';

class WordDetailCard extends StatelessWidget {
  final DictionaryEntry entry;
  final VoidCallback onSaved;

  const WordDetailCard({
    super.key,
    required this.entry,
    required this.onSaved,
  });

  void _showSaveToNotebookDialog(BuildContext context, {int? initialTopicId}) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final topics = appState.topics;

    if (topics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tạo ít nhất một chủ đề trong Notebook trước khi lưu!')),
      );
      return;
    }

    final savedVocab = appState.getSavedVocabulary(entry.word);
    final isSaved = savedVocab != null;

    int selectedTopicId = initialTopicId ??
        savedVocab?.topicId ??
        (topics.first.id ?? 1);

    // If selectedTopicId doesn't exist in topics list, pick first
    if (!topics.any((t) => t.id == selectedTopicId)) {
      selectedTopicId = topics.first.id!;
    }

    String firstDef = '';
    String firstPos = '';

    if (entry.meanings.isNotEmpty) {
      firstPos = entry.meanings.first.partOfSpeech;
      for (final m in entry.meanings) {
        if (m.definitions.isNotEmpty) {
          final d = m.definitions.first;
          firstDef = (d.vietnameseTranslation != null && d.vietnameseTranslation!.isNotEmpty)
              ? '${d.definition} (${d.vietnameseTranslation})'
              : d.definition;
          firstPos = m.partOfSpeech;
          break;
        }
      }
    }
    if (firstDef.isEmpty && entry.vietnameseMeaning != null) {
      firstDef = entry.vietnameseMeaning!;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    isSaved ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(isSaved ? 'Đổi chủ đề / Cập nhật' : 'Lưu vào Notebook'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Từ vựng: "${entry.word}"',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (isSaved) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Đã lưu trong: "${savedVocab.topicName ?? 'Chủ đề'}"',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Chọn chủ đề lưu trữ:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedTopicId,
                        isExpanded: true,
                        items: topics.map((t) {
                          return DropdownMenuItem<int>(
                            value: t.id,
                            child: Text(t.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedTopicId = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () async {
                    try {
                      await appState.saveVocabulary(
                        topicId: selectedTopicId,
                        word: entry.word,
                        definition: firstDef,
                        partOfSpeech: firstPos,
                        phoneticUk: entry.phoneticUk,
                        audioUrlUk: entry.audioUrlUk,
                        phoneticUs: entry.phoneticUs,
                        audioUrlUs: entry.audioUrlUs,
                        cefrLevel: entry.cefrLevel,
                        synonyms: entry.synonyms,
                        antonyms: entry.antonyms,
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      onSaved();
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Lỗi khi lưu từ: $e')),
                        );
                      }
                    }
                  },
                  child: Text(isSaved ? 'Cập nhật' : 'Lưu từ này'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context);
    final savedVocab = appState.getSavedVocabulary(entry.word);
    final isSaved = savedVocab != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word header & Save Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            entry.word,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          CefrBadge(level: entry.cefrLevel),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // UK & US Audio buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AudioButton(
                            label: 'UK',
                            phonetic: entry.phoneticUk,
                            audioUrl: entry.audioUrlUk,
                            color: theme.colorScheme.primary,
                          ),
                          AudioButton(
                            label: 'US',
                            phonetic: entry.phoneticUs,
                            audioUrl: entry.audioUrlUs,
                            color: theme.colorScheme.tertiary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isSaved)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => _showSaveToNotebookDialog(context, initialTopicId: savedVocab.topicId),
                    icon: const Icon(Icons.bookmark_added, size: 18),
                    label: Text(
                      savedVocab.topicName != null && savedVocab.topicName!.isNotEmpty
                          ? 'Đã lưu (${savedVocab.topicName})'
                          : 'Đã lưu vào Notebook',
                    ),
                  )
                else
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => _showSaveToNotebookDialog(context),
                    icon: const Icon(Icons.bookmark_add, size: 18),
                    label: const Text('Lưu vào Notebook'),
                  ),
              ],
            ),

            // Vietnamese Meaning banner
            if (entry.vietnameseMeaning != null && entry.vietnameseMeaning!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.translate, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nghĩa tiếng Việt: ${entry.vietnameseMeaning!}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Synonyms & Antonyms
            if (entry.synonyms.isNotEmpty || entry.antonyms.isNotEmpty) ...[
              const SizedBox(height: 14),
              if (entry.synonyms.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
                      children: [
                        const TextSpan(
                          text: 'Đồng nghĩa: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: entry.synonyms,
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              if (entry.antonyms.isNotEmpty)
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
                    children: [
                      const TextSpan(
                        text: 'Trái nghĩa: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: entry.antonyms,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
            ],

            const Divider(height: 28),

            // Meanings list
            ...entry.meanings.map((meaning) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        meaning.partOfSpeech.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...meaning.definitions.map((def) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ${def.definition}',
                              style: const TextStyle(fontSize: 14, height: 1.35),
                            ),
                            if (def.vietnameseTranslation != null &&
                                def.vietnameseTranslation!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 3, left: 14),
                                child: Text(
                                  '↳ ${def.vietnameseTranslation!}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            if (def.example != null && def.example!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 14),
                                child: Text(
                                  '"${def.example!}"',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
