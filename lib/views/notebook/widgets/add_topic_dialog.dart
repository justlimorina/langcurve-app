import 'package:flutter/material.dart';

class AddTopicDialog extends StatefulWidget {
  final Function(String name, String? desc) onAdd;

  const AddTopicDialog({super.key, required this.onAdd});

  @override
  State<AddTopicDialog> createState() => _AddTopicDialogState();
}

class _AddTopicDialogState extends State<AddTopicDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạo chủ đề mới'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên chủ đề *',
                hintText: 'Ví dụ: Trí tuệ nhân tạo, Du lịch...',
              ),
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên chủ đề';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Mô tả ngắn gọn',
                hintText: 'Nhập mô tả về chủ đề này...',
              ),
              maxLines: 2,
            ),
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
            if (_formKey.currentState!.validate()) {
              widget.onAdd(
                _nameController.text.trim(),
                _descController.text.trim().isEmpty ? null : _descController.text.trim(),
              );
              Navigator.of(context).pop();
            }
          },
          child: const Text('Tạo chủ đề'),
        ),
      ],
    );
  }
}
