import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class AudioButton extends StatefulWidget {
  final String label; // "UK" or "US"
  final String? phonetic;
  final String? audioUrl;
  final Color? color;

  const AudioButton({
    super.key,
    required this.label,
    this.phonetic,
    this.audioUrl,
    this.color,
  });

  @override
  State<AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends State<AudioButton> {
  bool _isPlaying = false;

  Future<void> _play() async {
    if (widget.audioUrl == null || widget.audioUrl!.isEmpty) return;
    setState(() => _isPlaying = true);
    await AudioService.instance.play(widget.audioUrl);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = widget.color ?? (widget.label == 'UK' ? theme.colorScheme.primary : theme.colorScheme.tertiary);

    return InkWell(
      onTap: widget.audioUrl != null && widget.audioUrl!.isNotEmpty ? _play : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.label}: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: accentColor,
              ),
            ),
            if (widget.phonetic != null && widget.phonetic!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  widget.phonetic!,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Icon(
              _isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
              size: 16,
              color: accentColor,
            ),
          ],
        ),
      ),
    );
  }
}
