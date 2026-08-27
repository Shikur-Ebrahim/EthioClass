import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../../config/api_config.dart';

class AuthService {
  static const String _baseUrl = apiBaseUrl;

  /// Utility to get a unique device identifier
  static Future<String> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      // Using androidId or a combination of manufacturer and model as identifier
      return '${androidInfo.manufacturer}_${androidInfo.model}_${androidInfo.id}';
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios_device';
    }
    return 'unknown_device';
  }

  Future<Map<String, dynamic>> signup({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final String deviceId = await _getDeviceId();

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'deviceId': deviceId,
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
    final String deviceId = await _getDeviceId();

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'deviceId': deviceId,
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
      body: jsonEncode({
        'email': email,
        'redirectTo': 'https://api.ethioclass.com/auth/callback',
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Failed to send reset link');
    }
  }

  Future<void> updatePassword({
    required String newPassword,
    required String accessToken,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/auth/update-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(data['error'] ?? 'Failed to update password');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String accessToken,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/auth/update-profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'email': email,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to update profile');
    }
  }

  /// Expose getDeviceId for security screen
  Future<String> getCurrentDeviceId() async {
    return await _getDeviceId();
  }
}
