import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformUtils {
  /// Trả về true nếu là nền tảng Desktop (Windows, Linux, macOS)
  static bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// Trả về true nếu là thiết bị di động (Android, iOS)
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
}
