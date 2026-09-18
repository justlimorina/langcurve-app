import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/topic.dart';
import '../../models/vocabulary.dart';
import '../../providers/app_state_provider.dart';
import 'widgets/practice_card.dart';

class PracticeView extends StatefulWidget {
  final VoidCallback onNavigateToDictionary;

  const PracticeView({
    super.key,
    required this.onNavigateToDictionary,
  });

  @override
  State<PracticeView> createState() => _PracticeViewState();
}

class _PracticeViewState extends State<PracticeView> {
  List<Vocabulary> _studyWords = [];
  int _studyIndex = 0;
  String _sessionTitle = '';
  bool _isSessionActive = false;
  int _sessionEarnedXp = 0;

  void _startSrsDuePractice(List<Vocabulary> dueWords) {
    if (dueWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tuyệt vời! Hiện tại không có từ vựng nào đến hạn ôn tập.')),
      );
      return;
    }

    final shuffled = List<Vocabulary>.from(dueWords)..shuffle(Random());
    setState(() {
      _studyWords = shuffled;
      _studyIndex = 0;
      _sessionTitle = 'Từ vựng đến hạn (SRS Due)';
      _isSessionActive = true;
      _sessionEarnedXp = 0;
    });
  }

  void _startAllPractice(List<Vocabulary> allWords) {
    if (allWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có từ vựng nào trong Notebook để ôn tập!')),
      );
      return;
    }

    final shuffled = List<Vocabulary>.from(allWords)..shuffle(Random());
    setState(() {
      _studyWords = shuffled;
      _studyIndex = 0;
      _sessionTitle = 'Tất cả từ vựng';
      _isSessionActive = true;
      _sessionEarnedXp = 0;
    });
  }

  Future<void> _startTopicPractice(Topic topic) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    await appState.selectTopic(topic);
    final vocabs = appState.topicVocabularies;

    if (vocabs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chủ đề "${topic.name}" chưa có từ vựng nào!')),
        );
      }
      return;
    }

    final shuffled = List<Vocabulary>.from(vocabs)..shuffle(Random());
    setState(() {
      _studyWords = shuffled;
      _studyIndex = 0;
      _sessionTitle = topic.name;
      _isSessionActive = true;
      _sessionEarnedXp = 0;
    });
  }

  Future<void> _handleReview(int quality, String? newSentence) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final currentVocab = _studyWords[_studyIndex];

    if (newSentence != null && newSentence.trim().isNotEmpty) {
      await appState.updateExample(currentVocab.id!, newSentence.trim());
    }

    await appState.recordSrsReview(
      vocabulary: currentVocab,
      quality: quality,
    );

    int earned = 0;
    if (quality == 5) earned = 20;
    else if (quality >= 3) earned = 10;
    _sessionEarnedXp += earned;

    if (mounted) {
      if (earned > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('+$earned XP! Ghi nhận thành công!'),
            duration: const Duration(milliseconds: 900),
          ),
        );
      }

      setState(() {
        _studyIndex++;
      });
    }
  }

  void _handleSkip() {
    _handleReview(0, null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context);

    // If Session is active and has words left
    if (_isSessionActive && _studyWords.isNotEmpty && _studyIndex < _studyWords.length) {
      final currentVocab = _studyWords[_studyIndex];

      return Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _isSessionActive = false),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Dừng ôn tập'),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.stars, size: 18, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '+$_sessionEarnedXp XP',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PracticeCard(
                vocabulary: currentVocab,
                currentIndex: _studyIndex,
                totalWords: _studyWords.length,
                topicName: _sessionTitle,
                onRecordReview: _handleReview,
                onSkip: _handleSkip,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _studyWords.shuffle(Random());
                      _studyIndex = 0;
                    });
                  },
                  icon: const Icon(Icons.shuffle, size: 16),
                  label: const Text('Trộn lại thẻ từ'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Completed Session screen
    if (_isSessionActive && _studyWords.isNotEmpty && _studyIndex >= _studyWords.length) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    size: 64,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Hoàn thành bài ôn tập!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn đã hoàn thành ôn tập ${_studyWords.length} từ vựng và nhận được +$_sessionEarnedXp XP.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    setState(() => _isSessionActive = false);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Quay về Menu Ôn tập'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Initial Mode Selection Menu
    final dueWords = appState.dueVocabularies;
    final allWords = appState.allVocabularies;
    final topics = appState.topics;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ôn tập cùng LangCurve',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ghi nhớ từ vựng lâu bền thông qua thuật toán lặp lại ngắt quãng SuperMemo SM-2 và thực hành tự đặt câu ví dụ.',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Mode 1: SRS Due Review Banner
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: dueWords.isNotEmpty
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant.withOpacity(0.5),
                  width: dueWords.isNotEmpty ? 2 : 1,
                ),
              ),
              color: dueWords.isNotEmpty
                  ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                  : theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: dueWords.isNotEmpty
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.alarm,
                        color: dueWords.isNotEmpty ? Colors.white : theme.colorScheme.outline,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Ôn tập từ vựng đến hạn (SRS Due)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (dueWords.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${dueWords.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dueWords.isNotEmpty
                                ? 'Có ${dueWords.length} từ vựng đã đến lịch ôn tập theo thuật toán SuperMemo SM-2.'
                                : 'Tất cả từ vựng đã được ôn tập đầy đủ. Hãy quay lại sau!',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: dueWords.isNotEmpty ? () => _startSrsDuePractice(dueWords) : null,
                      child: const Text('Bắt đầu'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Mode 2: Practice All Words
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_stories,
                        color: theme.colorScheme.onSecondaryContainer,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ôn tập tổng hợp tất cả từ vựng (${allWords.length} từ)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Luyện tập ngẫu nhiên tất cả các từ trong sổ tay của bạn.',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonal(
                      onPressed: allWords.isNotEmpty ? () => _startAllPractice(allWords) : null,
                      child: const Text('Luyện tập'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Mode 3: Practice by Topic
            Text(
              'Hoặc luyện tập theo từng chủ đề:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            if (topics.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Chưa có chủ đề nào trong sổ tay.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topics.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.folder, size: 20, color: theme.colorScheme.primary),
                    ),
                    title: Text(topic.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${topic.wordCount} từ vựng'),
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () => _startTopicPractice(topic),
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
