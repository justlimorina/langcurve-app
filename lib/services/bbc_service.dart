import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/api_endpoints.dart';
import '../models/bbc_video.dart';

class BbcService {
  static final BbcService instance = BbcService._internal();
  BbcService._internal();

  static final List<BbcVideo> _fallbackVideos = [
    BbcVideo(
      id: 'ut3b9qDHvEQ',
      title: 'Children in war zones ⏲️ 6 Minute English - BBC Learning English',
      desc: 'Khoa học từ vựng và chủ đề thời sự qua góc nhìn báo chí từ chương trình 6 Minute English của BBC.',
    ),
    BbcVideo(
      id: 'qRsLwL9lJQg',
      title: 'Social Media & News - BBC Learning English from the News',
      desc: 'Bản tin tiếng Anh phân tích xu hướng truyền thông với từ vựng chuẩn khung tham chiếu Châu Âu CEFR.',
    ),
    BbcVideo(
      id: 'wDFV1sZo1gY',
      title: 'Beating Speaking Anxiety - BBC Learning English Class',
      desc: 'Phương pháp vượt qua tâm lý e ngại khi giao tiếp tiếng Anh trực tiếp với giáo viên bản ngữ BBC.',
    ),
  ];

  static List<BbcVideo> get fallbackVideos => List.unmodifiable(_fallbackVideos);

  List<BbcVideo>? _cachedVideos;

  /// Fetches latest BBC Learning English videos from YouTube RSS feed or fallback
  Future<List<BbcVideo>> getVideos({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedVideos != null && _cachedVideos!.isNotEmpty) {
      return _cachedVideos!;
    }

    try {
      final response = await http
          .get(Uri.parse(ApiEndpoints.bbcLearningEnglishRss))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final xmlText = response.body;
        final entryRegex = RegExp(r'<entry>([\s\S]*?)<\/entry>');
        final matches = entryRegex.allMatches(xmlText);

        final videos = <BbcVideo>[];
        for (final m in matches) {
          if (videos.length >= 6) break;
          final block = m.group(1) ?? '';

          final videoIdMatch = RegExp(r'<yt:videoId>(.*?)<\/yt:videoId>').firstMatch(block);
          final titleMatch = RegExp(r'<title>(.*?)<\/title>').firstMatch(block);
          final descMatch = RegExp(r'<media:description>([\s\S]*?)<\/media:description>').firstMatch(block);
          final pubMatch = RegExp(r'<published>(.*?)<\/published>').firstMatch(block);

          if (videoIdMatch != null && titleMatch != null) {
            final id = videoIdMatch.group(1)!.trim();
            var title = titleMatch.group(1)!.trim()
                .replaceAll('&amp;', '&')
                .replaceAll('&lt;', '<')
                .replaceAll('&gt;', '>')
                .replaceAll('&#39;', "'")
                .replaceAll('&quot;', '"');

            var desc = descMatch != null ? descMatch.group(1)!.trim() : '';
            if (desc.contains('\n')) desc = desc.split('\n').first.trim();
            desc = desc.replaceAll(RegExp(r'http\S+'), '').trim();
            if (desc.length > 130) desc = '${desc.substring(0, 130)}...';
            if (desc.isEmpty) desc = 'Video bài học tiếng Anh từ kênh BBC Learning English.';

            videos.add(BbcVideo(
              id: id,
              title: title,
              desc: desc,
              publishedAt: pubMatch?.group(1),
            ));
          }
        }

        if (videos.isNotEmpty) {
          _cachedVideos = videos;
          return videos;
        }
      }
    } catch (e) {
      debugPrint('[BbcService] RSS sync failed, using fallback list: $e');
    }

    _cachedVideos = _fallbackVideos;
    return _fallbackVideos;
  }
}
