import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'database_service.dart';

class BackupService {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  /// Exports all progress into a JSON file
  Future<String?> exportToJsonFile() async {
    try {
      final data = await DatabaseService.instance.exportAllData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      final dateStr = DateTime.now().toIso8601String().split('T').first;
      final fileName = 'langcurve_backup_$dateStr.json';

      // Pick folder or save to documents/downloads
      String? outputPath;
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Chọn vị trí lưu file sao lưu LangCurve',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        outputPath = '${dir.path}/$fileName';
      }

      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsString(jsonString);
        return outputPath;
      }
    } catch (e) {
      debugPrint('[BackupService] Export failed: $e');
      rethrow;
    }
    return null;
  }

  /// Imports progress from a JSON file
  Future<bool> importFromJsonFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final content = await file.readAsString();
        final data = jsonDecode(content);

        if (data is Map<String, dynamic> &&
            data.containsKey('topics') &&
            data.containsKey('vocabularies')) {
          await DatabaseService.instance.importAllData(data);
          return true;
        } else {
          throw Exception('File JSON không đúng cấu trúc dữ liệu của LangCurve.');
        }
      }
    } catch (e) {
      debugPrint('[BackupService] Import failed: $e');
      rethrow;
    }
    return false;
  }
}
