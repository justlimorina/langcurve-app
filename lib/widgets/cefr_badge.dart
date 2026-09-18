import 'package:flutter/material.dart';

class CefrBadge extends StatelessWidget {
  final String level;
  final double fontSize;

  const CefrBadge({
    super.key,
    required this.level,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final clean = level.toUpperCase().trim();
    Color bgColor;
    Color textColor;

    switch (clean) {
      case 'A1':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'A2':
        bgColor = const Color(0xFFE0F2F1);
        textColor = const Color(0xFF00695C);
        break;
      case 'B1':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        break;
      case 'B2':
        bgColor = const Color(0xFFEDE7F6);
        textColor = const Color(0xFF512DA8);
        break;
      case 'C1':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        break;
      case 'C2':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC2185B);
        break;
      default:
        bgColor = Theme.of(context).colorScheme.surfaceContainerHigh;
        textColor = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    // In dark mode, adjust lightness for better contrast
    if (Theme.of(context).brightness == Brightness.dark) {
      bgColor = textColor.withOpacity(0.25);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withOpacity(0.4), width: 0.8),
      ),
      child: Text(
        clean,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
