import 'package:flutter/material.dart';

class SrsRatingBar extends StatelessWidget {
  final Function(int quality) onRatingSelected;

  const SrsRatingBar({
    super.key,
    required this.onRatingSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đánh giá mức độ ghi nhớ (Thuật toán SuperMemo SM-2):',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Rating 0: Again
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade800,
                side: BorderSide(color: Colors.red.shade200),
              ),
              onPressed: () => onRatingSelected(0),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.replay, size: 16),
                  SizedBox(width: 4),
                  Text('Chưa nhớ (0)'),
                ],
              ),
            ),
            // Rating 3: Hard
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade50,
                foregroundColor: Colors.orange.shade900,
                side: BorderSide(color: Colors.orange.shade200),
              ),
              onPressed: () => onRatingSelected(3),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sentiment_neutral, size: 16),
                  SizedBox(width: 4),
                  Text('Khó (+10 XP)'),
                ],
              ),
            ),
            // Rating 4: Good
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue.shade900,
                side: BorderSide(color: Colors.blue.shade200),
              ),
              onPressed: () => onRatingSelected(4),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sentiment_satisfied, size: 16),
                  SizedBox(width: 4),
                  Text('Tốt (+10 XP)'),
                ],
              ),
            ),
            // Rating 5: Easy
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () => onRatingSelected(5),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sentiment_very_satisfied, size: 16),
                  SizedBox(width: 4),
                  Text('Rất dễ (+20 XP)'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
