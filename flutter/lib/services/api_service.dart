import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// ApiService handles all HTTP communication with the EthioClass Go backend.
///
/// Backend target: https://api.ethioclass.com
/// (Flutter → Cloudflare → Contabo VPS → Nginx → Go Docker container)
class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Calls GET /health and returns the parsed response body.
  /// Throws an [Exception] if the request fails or returns a non-200 status.
  Future<Map<String, dynamic>> healthCheck() async {
    final uri = Uri.parse('$apiBaseUrl/health');
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Health check failed: HTTP ${response.statusCode}');
    }
  }
}
