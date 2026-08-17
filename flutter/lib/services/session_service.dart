import 'package:shared_preferences/shared_preferences.dart';

/// Handles saving and loading user session data locally.
/// Used for persistent login — if a session exists, skip the login screen.
class SessionService {
  static const _keyToken = 'session_token';
  static const _keyUserName = 'session_user_name';
  static const _keyUserEmail = 'session_user_email';
  static const _keyUserPhone = 'session_user_phone';

  /// Save session after successful login
  static Future<void> saveSession({
    required String token,
    required String userName,
    required String userEmail,
    required String userPhone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUserName, userName);
    await prefs.setString(_keyUserEmail, userEmail);
    await prefs.setString(_keyUserPhone, userPhone);
  }

  /// Load existing session. Returns null if no session exists.
  static Future<Map<String, String>?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null || token.isEmpty) return null;
    return {
      'token': token,
      'userName': prefs.getString(_keyUserName) ?? '',
      'userEmail': prefs.getString(_keyUserEmail) ?? '',
      'userPhone': prefs.getString(_keyUserPhone) ?? '',
    };
  }

  /// Clear session on logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserPhone);
  }

  /// Check if a session exists
  static Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    return token != null && token.isNotEmpty;
  }
}
