import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/topic.dart';
import '../../providers/app_state_provider.dart';
import 'widgets/vocab_card.dart';

class TopicDetailView extends StatefulWidget {
  final Topic topic;
  final VoidCallback onBack;
  final VoidCallback onNavigateToDictionary;

  const TopicDetailView({
    super.key,
    required this.topic,
    required this.onBack,
    required this.onNavigateToDictionary,
  });

  @override
  State<TopicDetailView> createState() => _TopicDetailViewState();
}

class _TopicDetailViewState extends State<TopicDetailView> {
  String _filterQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context);
    final vocabs = appState.topicVocabularies.where((v) {
      if (_filterQuery.isEmpty) return true;
      return v.word.toLowerCase().contains(_filterQuery.toLowerCase()) ||
          v.definition.toLowerCase().contains(_filterQuery.toLowerCase());
    }).toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            OutlinedButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Quay lại Notebook'),
            ),

            const SizedBox(height: 16),

            // Topic Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.topic.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${appState.topicVocabularies.length} từ vựng',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.topic.description != null &&
                      widget.topic.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.topic.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Actions & Filter Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm từ vựng trong chủ đề...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      isDense: true,
                    ),
                    onChanged: (text) => setState(() => _filterQuery = text),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: widget.onNavigateToDictionary,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm từ mới'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Vocab List
            if (vocabs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 48,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _filterQuery.isEmpty
                          ? 'Chưa có từ vựng nào trong chủ đề này.'
                          : 'Không tìm thấy từ vựng khớp với "$_filterQuery".',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: widget.onNavigateToDictionary,
                      icon: const Icon(Icons.search),
                      label: const Text('Đi tra từ mới & Lưu vào đây'),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vocabs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final v = vocabs[index];
                  return VocabCard(
                    vocab: v,
                    onEditExample: (newEx) async {
                      await appState.updateExample(v.id!, newEx);
                    },
                    onDelete: () async {
                      await appState.deleteVocabulary(v.id!);
                    },
                  );
                },
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
