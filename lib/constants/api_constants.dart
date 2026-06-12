import 'package:flutter/foundation.dart';

class ApiConstants {
  // Use http://10.0.2.2:8000 for Android Emulator.
  // Use http://localhost:8000 for iOS Simulator/Desktop.
  // Switch to your PC's local IP address (e.g. 192.168.1.X) if running on physical devices.
  static const String prodUrl = 'https://macacino.vercel.app';
  static const String devUrl = 'http://192.168.18.188:8000';

  static String baseUrl = kReleaseMode ? prodUrl : devUrl;

  static String get loginUrl => '$baseUrl/api/auth/login';
  static String get registerUrl => '$baseUrl/api/auth/register';
  static String get logoutUrl => '$baseUrl/api/auth/logout';
  static String get userUrl => '$baseUrl/api/user';
  static String get statsUrl => '$baseUrl/api/stats';
  static String get documentsUrl => '$baseUrl/api/documents';
  static String get uploadDocumentUrl => '$baseUrl/api/documents/upload';

  static String documentDetailUrl(int id) => '$baseUrl/api/documents/$id';
  static String downloadDocumentUrl(int id) =>
      '$baseUrl/api/documents/$id/download';
  static String updateProgressUrl(int id) =>
      '$baseUrl/api/documents/$id/progress';
  static String updateTotalPagesUrl(int id) =>
      '$baseUrl/api/documents/$id/total-pages';
  static String deleteDocumentUrl(int id) => '$baseUrl/api/documents/$id';
  static String get bulkDeleteDocumentsUrl =>
      '$baseUrl/api/documents/bulk-delete';

  static String getHighlightsUrl(int docId) =>
      '$baseUrl/api/documents/$docId/highlights';
  static String get createHighlightUrl => '$baseUrl/api/highlights';
  static String get createAiNoteUrl => '$baseUrl/api/highlights/ai-note';
  static String deleteHighlightUrl(int id) => '$baseUrl/api/highlights/$id';

  static String get aiExplainUrl => '$baseUrl/api/ai/explain';
  static String get aiTtsUrl => '$baseUrl/api/ai/tts';
  static String get updatePasswordUrl => '$baseUrl/api/profile/update-password';
}
