import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/download_result.dart';

class ApiService {
  // Yahan apna Railway URL daalo deploy ke baad
  static const String _baseUrl = 'https://YOUR-APP.up.railway.app';

  static Future<DownloadResult> getDownloadLinks({
    required String url,
    String quality = '720',
    bool audioOnly = false,
    String audioFormat = 'mp3',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/download'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'url': url,
          'quality': quality,
          'audioOnly': audioOnly,
          'audioFormat': audioFormat,
        }),
      ).timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return DownloadResult.fromJson(data);
      } else {
        throw Exception(data['error'] ?? 'Download failed');
      }
    } on Exception catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }
}
