import 'package:flutter/material.dart';

import '../models/bbc_video.dart';
import '../models/curve_data_point.dart';
import '../models/topic.dart';
import '../models/vocabulary.dart';
import '../services/bbc_service.dart';
import '../services/database_service.dart';
import '../services/srs_service.dart';
import '../services/tracking_service.dart';

class AppStateProvider extends ChangeNotifier {
  List<Topic> _topics = [];
  Topic? _selectedTopic;
  List<Vocabulary> _topicVocabularies = [];
  List<Vocabulary> _dueVocabularies = [];
  List<Vocabulary> _allVocabularies = [];
  List<CurveDataPoint> _curvePoints = [];
  List<BbcVideo> _bbcVideos = [];

  Map<String, dynamic> _stats = {
    'totalXp': 0,
    'totalWords': 0,
    'totalExamples': 0,
    'recentWords': <String>[],
    'levelTitle': 'Tập sự (Novice)',
  };

  bool _isLoading = false;

  // Getters
  List<Topic> get topics => _topics;
  Topic? get selectedTopic => _selectedTopic;
  List<Vocabulary> get topicVocabularies => _topicVocabularies;
  List<Vocabulary> get dueVocabularies => _dueVocabularies;
  List<Vocabulary> get allVocabularies => _allVocabularies;
  List<CurveDataPoint> get curvePoints => _curvePoints;
  List<BbcVideo> get bbcVideos => _bbcVideos;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;

  int get totalXp => (_stats['totalXp'] ?? 0) as int;
  int get totalWords => (_stats['totalWords'] ?? 0) as int;
  int get totalExamples => (_stats['totalExamples'] ?? 0) as int;
  List<String> get recentWords => (_stats['recentWords'] as List<dynamic>? ?? []).cast<String>();
  String get levelTitle => (_stats['levelTitle'] ?? 'Tập sự (Novice)') as String;

  AppStateProvider() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await loadTopics();
    await refreshStats();
    await refreshDueVocabularies();
    await refreshLearningCurve();
    await refreshBbcVideos();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTopics() async {
    _topics = await DatabaseService.instance.getTopics();
    notifyListeners();
  }

  Future<void> selectTopic(Topic? topic) async {
    _selectedTopic = topic;
    if (topic != null && topic.id != null) {
      _topicVocabularies = await DatabaseService.instance.getVocabularies(topicId: topic.id);
    } else {
      _topicVocabularies = [];
    }
    notifyListeners();
  }

  Future<void> refreshTopicVocabularies() async {
    if (_selectedTopic != null && _selectedTopic!.id != null) {
      _topicVocabularies = await DatabaseService.instance.getVocabularies(topicId: _selectedTopic!.id);
      notifyListeners();
    }
  }

  Future<Topic> createTopic(String name, String? description) async {
    final newTopic = await DatabaseService.instance.createTopic(name, description);
    await loadTopics();
    return newTopic;
  }

  Future<void> deleteTopic(int topicId) async {
    await DatabaseService.instance.deleteTopic(topicId);
    if (_selectedTopic?.id == topicId) {
      _selectedTopic = null;
      _topicVocabularies = [];
    }
    await loadTopics();
    await refreshStats();
  }

  Future<Vocabulary> saveVocabulary({
    required int topicId,
    required String word,
    String? definition,
    String? partOfSpeech,
    String? phoneticUk,
    String? audioUrlUk,
    String? phoneticUs,
    String? audioUrlUs,
    String? userExample,
    String? cefrLevel,
    String? synonyms,
    String? antonyms,
  }) async {
    final vocab = await DatabaseService.instance.upsertVocabulary(
      topicId: topicId,
      word: word,
      definition: definition,
      partOfSpeech: partOfSpeech,
      phoneticUk: phoneticUk,
      audioUrlUk: audioUrlUk,
      phoneticUs: phoneticUs,
      audioUrlUs: audioUrlUs,
      userExample: userExample,
      cefrLevel: cefrLevel,
      synonyms: synonyms,
      antonyms: antonyms,
    );

    await loadTopics();
    await refreshStats();
    await refreshDueVocabularies();
    if (_selectedTopic?.id == topicId) {
      await refreshTopicVocabularies();
    }
    return vocab;
  }

  Future<void> updateExample(int vocabId, String example) async {
    await DatabaseService.instance.updateExample(vocabId, example);
    await refreshStats();
    if (_selectedTopic != null) {
      await refreshTopicVocabularies();
    }
  }

  Future<void> deleteVocabulary(int vocabId) async {
    await DatabaseService.instance.deleteVocabulary(vocabId);
    await loadTopics();
    await refreshStats();
    await refreshDueVocabularies();
    if (_selectedTopic != null) {
      await refreshTopicVocabularies();
    }
  }

  Future<Vocabulary> recordSrsReview({
    required Vocabulary vocabulary,
    required int quality,
  }) async {
    final updated = await SrsService.instance.recordReview(
      vocabulary: vocabulary,
      quality: quality,
    );

    await refreshStats();
    await refreshDueVocabularies();
    await refreshLearningCurve();
    if (_selectedTopic != null) {
      await refreshTopicVocabularies();
    }
    return updated;
  }

  Future<void> refreshDueVocabularies() async {
    _dueVocabularies = await DatabaseService.instance.getDueVocabularies();
    _allVocabularies = await DatabaseService.instance.getVocabularies();
    notifyListeners();
  }

  Future<void> refreshStats() async {
    _stats = await DatabaseService.instance.getDashboardStats();
    notifyListeners();
  }

  Future<void> refreshLearningCurve() async {
    _curvePoints = await TrackingService.instance.getLearningCurveData();
    notifyListeners();
  }

  Future<void> refreshBbcVideos() async {
    _bbcVideos = await BbcService.instance.getVideos();
    notifyListeners();
  }

  Future<void> reloadAfterImport() async {
    await init();
  }
}
