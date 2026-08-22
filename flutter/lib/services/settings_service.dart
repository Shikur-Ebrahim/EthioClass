import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/api_config.dart';
import '../models/user_settings.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._internal();
  static const String _baseUrl = apiBaseUrl;
  
  SettingsService._internal();

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('device_user_id');
    if (userId == null) {
      userId = const Uuid().v4();
      await prefs.setString('device_user_id', userId);
    }
    return userId;
  }

  Future<UserSettings> getSettings() async {
    try {
      final userId = await _getUserId();
      final response = await http.get(Uri.parse('\/settings?user_id=\'));
      
      if (response.statusCode == 200) {
        return UserSettings.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error fetching settings: \');
    }
    return UserSettings(); // Returns defaults
  }

  Future<bool> updateSettings(UserSettings settings) async {
    try {
      final userId = await _getUserId();
      final body = settings.toJson();
      body['user_id'] = userId;

      final response = await http.put(
        Uri.parse('\/settings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating settings: \');
      return false;
    }
  }
}
