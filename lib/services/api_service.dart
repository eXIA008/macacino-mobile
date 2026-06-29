import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/api_constants.dart';

class ApiService {
  final String? _token;

  ApiService(this._token);

  String? get token => _token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String url) async {
    final response = await http.get(Uri.parse(url), headers: _headers);
    return _handleResponse(response);
  }

  Future<dynamic> post(String url, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String url, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse(url),
      headers: _headers,
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String url) async {
    final response = await http.delete(Uri.parse(url), headers: _headers);
    return _handleResponse(response);
  }

  Future<Uint8List> downloadFileBytes(String url) async {
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    } else {
      throw Exception('Gagal mengunduh file: Kode status ${response.statusCode}');
    }
  }

  Future<dynamic> uploadDocument({
    String? filePath,
    Uint8List? bytes,
    required String fileName,
    required String title,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(ApiConstants.uploadDocumentUrl));
    
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.headers['Accept'] = 'application/json';

    request.fields['title'] = title;

    if (kIsWeb) {
      if (bytes == null) {
        throw Exception("File bytes are required on Web platform");
      }
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: MediaType('application', 'pdf'),
      );
      request.files.add(multipartFile);
    } else {
      if (filePath == null) {
        throw Exception("File path is required on native platforms");
      }
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: fileName,
        contentType: MediaType('application', 'pdf'),
      );
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Future<String> fetchTtsAudio(String text, String accent) async {
    if (kIsWeb) {
      final response = await http.post(
        Uri.parse(ApiConstants.aiTtsUrl),
        headers: _headers,
        body: json.encode({'text': text, 'accent': accent}),
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        return 'data:audio/mpeg;base64,${base64Encode(bytes)}';
      } else {
        final errData = json.decode(response.body);
        throw Exception(errData['message'] ?? 'Gagal memproses suara TTS.');
      }
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      final now = DateTime.now();
      for (final entity in files) {
        if (entity is File && 
            entity.path.split('/').last.startsWith('tts_') && 
            entity.path.endsWith('.mp3')) {
          final stat = entity.statSync();
          if (now.difference(stat.modified).inSeconds > 30) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      print('Error cleaning up old TTS files: $e');
    }

    final response = await http.post(
      Uri.parse(ApiConstants.aiTtsUrl),
      headers: _headers,
      body: json.encode({'text': text, 'accent': accent}),
    );

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final tempDir = await getTemporaryDirectory();
      final uniqueFileName = 'tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final tempFile = File('${tempDir.path}/$uniqueFileName');
      await tempFile.writeAsBytes(bytes);
      return tempFile.path;
    } else {
      final errData = json.decode(response.body);
      throw Exception(errData['message'] ?? 'Gagal memproses suara TTS.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final int statusCode = response.statusCode;
    
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else if (statusCode == 401) {
      throw Exception('Unauthorized: Silakan login kembali.');
    } else if (statusCode == 422) {
      final decoded = json.decode(response.body);
      final errors = decoded['errors'] as Map<String, dynamic>?;
      final firstError = errors?.values.first?.first;
      throw Exception(firstError ?? decoded['message'] ?? 'Validasi gagal.');
    } else {
      try {
        final decoded = json.decode(response.body);
        throw Exception(decoded['message'] ?? decoded['error'] ?? 'Terjadi kesalahan server.');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Kesalahan server dengan kode status: $statusCode');
      }
    }
  }
}
