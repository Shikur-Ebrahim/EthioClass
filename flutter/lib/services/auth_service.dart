import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class AuthService {
  static const String _baseUrl = apiBaseUrl;

  Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Signup failed');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Login failed');
    }
  }

  Future<void> resetPassword({required String email}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Failed to send reset link');
    }
  }
}
