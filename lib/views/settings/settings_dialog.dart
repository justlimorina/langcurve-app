import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/backup_service.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.settings_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Cài đặt & Thiết lập'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Giao diện ứng dụng',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Sáng'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Tối'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('Hệ thống'),
                ),
              ],
              selected: {themeProvider.themeMode},
              onSelectionChanged: (Set<ThemeMode> selection) {
                themeProvider.setThemeMode(selection.first);
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Dữ liệu & Tiến trình học',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.download, color: theme.colorScheme.onPrimaryContainer),
              ),
              title: const Text('Xuất tiến trình (JSON)'),
              subtitle: const Text('Lưu sao lưu từ vựng, chủ đề và điểm XP ra máy'),
              onTap: () async {
                try {
                  final path = await BackupService.instance.exportToJsonFile();
                  if (context.mounted && path != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã xuất file sao lưu thành công:\n$path')),
                    );
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi xuất dữ liệu: $e')),
                    );
                  }
                }
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.upload, color: theme.colorScheme.onSecondaryContainer),
              ),
              title: const Text('Nhập tiến trình (JSON)'),
              subtitle: const Text('Khôi phục lại dữ liệu học tập từ file sao lưu'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cảnh báo ghi đè'),
                    content: const Text(
                      'Nhập file sao lưu sẽ thay thế toàn bộ dữ liệu hiện tại trong ứng dụng. Bạn có chắc chắn muốn tiếp tục?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Hủy'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Đồng ý'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    final success = await BackupService.instance.importFromJsonFile();
                    if (success && context.mounted) {
                      await appState.reloadAfterImport();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Khôi phục tiến trình thành công!')),
                      );
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi khi nhập dữ liệu: $e')),
                      );
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            Center(
              child: Text(
                'LangCurve Flutter v1.0.0\nMaterial Design 3 English Learning',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
