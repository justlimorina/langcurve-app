import 'package:flutter/material.dart';
import '../../models/dictionary_entry.dart';
import '../../services/dictionary_service.dart';
import 'widgets/word_detail_card.dart';

class DictionaryView extends StatefulWidget {
  const DictionaryView({super.key});

  @override
  State<DictionaryView> createState() => _DictionaryViewState();
}

class _DictionaryViewState extends State<DictionaryView> {
  final TextEditingController _searchController = TextEditingController();
  DictionaryEntry? _currentEntry;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _suggestions = [
    'algorithm',
    'collaborate',
    'sustainable',
    'meticulous',
    'epiphany',
    'paradigm',
  ];

  Future<void> _searchWord(String word) async {
    final clean = word.trim();
    if (clean.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentEntry = null;
    });

    try {
      final entry = await DictionaryService.instance.lookupWord(clean);
      if (entry != null) {
        setState(() {
          _currentEntry = entry;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Không tìm thấy từ vựng "$clean". Vui lòng kiểm tra lại chính tả.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tra cứu: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Từ điển thông minh',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tra cứu từ vựng với bộ phân tích hình thái (Lemmatizer), phát âm chuẩn UK/US kép và dịch tự động.',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Search Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Nhập từ tiếng Anh cần tra (ví dụ: study, went, criteria...)',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (text) => setState(() {}),
                    onSubmitted: (text) => _searchWord(text),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _searchWord(_searchController.text),
                  icon: const Icon(Icons.search),
                  label: const Text('Tra từ'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Suggestions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Gợi ý:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                ..._suggestions.map(
                  (s) => ActionChip(
                    label: Text(s),
                    labelStyle: const TextStyle(fontSize: 12),
                    onPressed: () {
                      _searchController.text = s;
                      _searchWord(s);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Loading state
            if (_isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Đang truy vấn từ điển trực tuyến & phân tích ngữ pháp...',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),

            // Error state
            if (_errorMessage != null && !_isLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Result Card
            if (_currentEntry != null && !_isLoading)
              WordDetailCard(
                entry: _currentEntry!,
                onSaved: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã lưu từ "${_currentEntry!.word}" vào Notebook!'),
                    ),
                  );
                },
              ),

            // Empty state initial guide
            if (_currentEntry == null && !_isLoading && _errorMessage == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 64,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Khám phá từ vựng mới',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gõ bất kỳ từ vựng tiếng Anh nào ở thanh tìm kiếm phía trên để tra phiên âm, nghe giọng bản ngữ và lưu vào sổ tay học tập.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
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
