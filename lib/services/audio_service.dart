import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService instance = AudioService._internal();
  AudioService._internal();

  AudioPlayer? _player;

  AudioPlayer get player {
    _player ??= AudioPlayer();
    return _player!;
  }

  /// Plays pronunciation audio from a given URL
  Future<void> play(String? audioUrl) async {
    if (audioUrl == null || audioUrl.trim().isEmpty) return;

    try {
      await player.stop();
      await player.play(UrlSource(audioUrl.trim()));
    } catch (e) {
      debugPrint('[AudioService] Playback error for $audioUrl: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  void dispose() {
    _player?.dispose();
    _player = null;
  }
}
