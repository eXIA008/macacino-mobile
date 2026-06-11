import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../constants/api_constants.dart';
import '../services/api_service.dart';

class BookDocument {
  final int id;
  final String title;
  final String filename;
  final int totalPages;
  final int lastPage;
  final DateTime? lastReadAt;
  final DateTime createdAt;

  BookDocument({
    required this.id,
    required this.title,
    required this.filename,
    required this.totalPages,
    required this.lastPage,
    this.lastReadAt,
    required this.createdAt,
  });

  String get fileUrl => ApiConstants.downloadDocumentUrl(id);

  double get progressPercentage {
    if (totalPages == 0) return 0.0;
    final progress = lastPage / totalPages;
    return progress > 1.0 ? 1.0 : progress;
  }

  factory BookDocument.fromJson(Map<String, dynamic> json) {
    return BookDocument(
      id: json['id'],
      title: json['title'] ?? '',
      filename: json['filename'] ?? '',
      totalPages: json['total_pages'] ?? 0,
      lastPage: json['last_page'] ?? 1,
      lastReadAt: json['last_read_at'] != null
          ? DateTime.parse(json['last_read_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

class Highlight {
  final int id;
  final int documentId;
  final int pageNumber;
  final String textContent;
  final String? note;
  final double x;
  final double y;
  final double width;
  final double height;
  final String? aiTranslation;
  final String? aiExplanation;
  final dynamic aiVocabulary;
  final String? aiGrammar;
  final String? aiIdiomNote;
  final String color;
  final DateTime createdAt;
  final List<String> collocations;
  final String? tip;
  final String? nuance;
  final String? tenseInfo;
  final String? aiDetailsJson;

  Highlight({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.textContent,
    this.note,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.aiTranslation,
    this.aiExplanation,
    this.aiVocabulary,
    this.aiGrammar,
    this.aiIdiomNote,
    required this.color,
    required this.createdAt,
    this.collocations = const [],
    this.tip,
    this.nuance,
    this.tenseInfo,
    this.aiDetailsJson,
  });

  factory Highlight.fromJson(Map<String, dynamic> json) {
    final pos = json['position'] ?? {};
    final ai = json['ai_analysis'] ?? {};

    Map<String, dynamic> details = {};
    final rawDetails = json['ai_details'];
    if (rawDetails != null) {
      if (rawDetails is String) {
        try {
          details = jsonDecode(rawDetails);
        } catch (e) {
          debugPrint('Error parsing ai_details: $e');
        }
      } else if (rawDetails is Map) {
        details = Map<String, dynamic>.from(rawDetails);
      }
    }

    final collocationsRaw = details['collocations'] ?? [];
    final collocations = List<String>.from(collocationsRaw);
    final tip = details['tip'] as String?;
    final nuance = details['nuance'] as String?;
    final tenseInfo = details['tense_info'] as String?;

    return Highlight(
      id: json['id'],
      documentId: json['document_id'],
      pageNumber: json['page_number'],
      textContent: json['text_content'] ?? '',
      note: json['note'],
      x: _toDouble(pos['x']),
      y: _toDouble(pos['y']),
      width: _toDouble(pos['width']),
      height: _toDouble(pos['height']),
      aiTranslation: ai['translation'] ?? details['translation'],
      aiExplanation: ai['explanation'] ?? details['explanation'],
      aiVocabulary: ai['vocabulary'] ?? details['vocabulary'],
      aiGrammar: ai['grammar'] ?? details['grammar'] ?? json['ai_grammar'],
      aiIdiomNote: ai['idiom_note'] ?? details['idiom_note'] ?? json['ai_idiom_note'],
      color: json['color'] ?? 'rgba(255, 213, 79, 0.3)',
      createdAt: DateTime.parse(json['created_at']),
      collocations: collocations,
      tip: tip,
      nuance: nuance,
      tenseInfo: tenseInfo,
      aiDetailsJson: rawDetails is String ? rawDetails : (rawDetails != null ? jsonEncode(rawDetails) : null),
    );
  }
}

class StatsData {
  final int streakDays;
  final int finishedBooks;
  final int totalWords;
  final List<String> docTitles;
  final List<int> docProgress;
  final List<String> vocabTitles;
  final List<int> vocabCounts;

  StatsData({
    required this.streakDays,
    required this.finishedBooks,
    required this.totalWords,
    required this.docTitles,
    required this.docProgress,
    required this.vocabTitles,
    required this.vocabCounts,
  });

  factory StatsData.fromJson(Map<String, dynamic> json) {
    final docs = json['documents'] ?? {};
    final vocabs = json['vocabulary_stats'] ?? {};
    return StatsData(
      streakDays: json['streak_days'] ?? 0,
      finishedBooks: json['finished_books'] ?? 0,
      totalWords: json['total_words'] ?? 0,
      docTitles: List<String>.from(docs['titles'] ?? []),
      docProgress: List<int>.from(docs['progress'] ?? []),
      vocabTitles: List<String>.from(vocabs['titles'] ?? []),
      vocabCounts: List<int>.from(vocabs['counts'] ?? []),
    );
  }
}

// Provider
class DocumentProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<BookDocument> _documents = [];
  bool _isLoading = false;
  StatsData? _stats;

  List<BookDocument> get documents => _documents;
  bool get isLoading => _isLoading;
  StatsData? get stats => _stats;
  String? get token => _apiService.token;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  DocumentProvider(this._apiService) {
    _audioPlayer.onPlayerComplete.listen((event) {
      _isSpeaking = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> fetchDocuments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get(ApiConstants.documentsUrl);
      if (response != null && response['data'] != null) {
        final List<dynamic> list = response['data'];
        _documents = list.map((item) => BookDocument.fromJson(item)).toList();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Download raw document bytes
  Future<Uint8List> loadDocumentBytes(String url) async {
    return await _apiService.downloadFileBytes(url);
  }

  // Upload a new document (web-compatible support)
  Future<void> uploadDocument({
    String? filePath,
    Uint8List? bytes,
    required String fileName,
    required String title,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.uploadDocument(
        filePath: filePath,
        bytes: bytes,
        fileName: fileName,
        title: title,
      );
      await fetchDocuments();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a document
  Future<void> deleteDocument(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.delete(ApiConstants.deleteDocumentUrl(id));
      _documents.removeWhere((doc) => doc.id == id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sync reading progress
  Future<void> updateProgress(int id, int page) async {
    try {
      await _apiService.put(ApiConstants.updateProgressUrl(id), {'page': page});
      // Update local state without full reload
      final index = _documents.indexWhere((doc) => doc.id == id);
      if (index != -1) {
        final doc = _documents[index];
        _documents[index] = BookDocument(
          id: doc.id,
          title: doc.title,
          filename: doc.filename,
          totalPages: doc.totalPages,
          lastPage: page,
          lastReadAt: DateTime.now(),
          createdAt: doc.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing progress: $e');
    }
  }

  // Sync total pages
  Future<void> updateTotalPages(int id, int totalPages) async {
    try {
      await _apiService.put(ApiConstants.updateTotalPagesUrl(id), {
        'total_pages': totalPages,
      });
      final index = _documents.indexWhere((doc) => doc.id == id);
      if (index != -1) {
        final doc = _documents[index];
        _documents[index] = BookDocument(
          id: doc.id,
          title: doc.title,
          filename: doc.filename,
          totalPages: totalPages,
          lastPage: doc.lastPage,
          lastReadAt: doc.lastReadAt,
          createdAt: doc.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating total pages: $e');
    }
  }

  // Fetch highlights for a document
  Future<List<Highlight>> fetchHighlights(int docId, {int? page}) async {
    try {
      String url = ApiConstants.getHighlightsUrl(docId);
      if (page != null) {
        url += '?page=$page';
      }
      final response = await _apiService.get(url);
      if (response != null && response['data'] != null) {
        final List<dynamic> list = response['data'];
        return list.map((item) => Highlight.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching highlights: $e');
    }
    return [];
  }

  // Save an AI note highlight
  Future<Highlight> createAiNote({
    required int documentId,
    required int pageNumber,
    required String textContent,
    required String explanation,
    required String translation,
    required Map<String, dynamic> details,
    String color = 'rgba(33, 150, 243, 0.3)', // Light blue
  }) async {
    final response = await _apiService.post(ApiConstants.createAiNoteUrl, {
      'document_id': documentId,
      'page_number': pageNumber,
      'text_content': textContent,
      'ai_explanation': explanation,
      'ai_translation': translation,
      'ai_details': json.encode(details),
      'color': color,
    });

    if (response != null && response['data'] != null) {
      return Highlight.fromJson(response['data']);
    } else {
      throw Exception('Gagal menyimpan catatan AI.');
    }
  }

  // Save standard highlight
  Future<Highlight> createHighlight({
    required int documentId,
    required int pageNumber,
    required String textContent,
    required double x,
    required double y,
    required double width,
    required double height,
    String color = 'rgba(255, 213, 79, 0.3)', // Light yellow
  }) async {
    final response = await _apiService.post(ApiConstants.createHighlightUrl, {
      'document_id': documentId,
      'page_number': pageNumber,
      'text_content': textContent,
      'position_x': x,
      'position_y': y,
      'position_width': width,
      'position_height': height,
      'color': color,
    });

    if (response != null && response['data'] != null) {
      return Highlight.fromJson(response['data']);
    } else {
      throw Exception('Gagal menyimpan stabilo.');
    }
  }

  // Delete a highlight
  Future<void> deleteHighlight(int id) async {
    await _apiService.delete(ApiConstants.deleteHighlightUrl(id));
  }

  // Fetch statistics
  Future<void> fetchStats() async {
    try {
      final response = await _apiService.get(ApiConstants.statsUrl);
      if (response != null && response['data'] != null) {
        _stats = StatsData.fromJson(response['data']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  // Call AI explain API
  Future<Map<String, dynamic>> explainText(
    String text,
    String contextText,
  ) async {
    final response = await _apiService.post(ApiConstants.aiExplainUrl, {
      'text': text,
      'context': contextText,
    });

    if (response != null && response['data'] != null) {
      return response['data'];
    } else {
      throw Exception('Format respons penjelasan AI tidak valid.');
    }
  }

  // Fetch and play TTS audio
  Future<void> speak(String text, String accent) async {
    if (_isSpeaking) {
      await _audioPlayer.stop();
      _isSpeaking = false;
      notifyListeners();
      return;
    }

    _isSpeaking = true;
    notifyListeners();

    try {
      final filePath = await _apiService.fetchTtsAudio(text, accent);
      if (filePath.startsWith('data:') || filePath.startsWith('http')) {
        await _audioPlayer.play(UrlSource(filePath));
      } else {
        await _audioPlayer.play(DeviceFileSource(filePath));
      }
    } catch (e) {
      _isSpeaking = false;
      notifyListeners();
      rethrow;
    }
  }
}
