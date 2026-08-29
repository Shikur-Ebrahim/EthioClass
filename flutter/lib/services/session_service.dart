import 'package:shared_preferences/shared_preferences.dart';

/// Handles saving and loading user session data locally.
/// Used for persistent login — if a session exists, skip the login screen.
class SessionService {
  static const _keyToken = 'session_token';
  static const _keyUserName = 'session_user_name';
  static const _keyUserEmail = 'session_user_email';
  static const _keyUserPhone = 'session_user_phone';
  static const _keyUserRole = 'session_user_role';

  /// Save session after successful login
  static Future<void> saveSession({
    required String token,
    required String userName,
    required String userEmail,
    required String userPhone,
    required String userRole,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUserName, userName);
    await prefs.setString(_keyUserEmail, userEmail);
    await prefs.setString(_keyUserPhone, userPhone);
    await prefs.setString(_keyUserRole, userRole);
    await prefs.setBool(_keyHasRegistered, true);
  }

  /// Load existing session. Returns null if no session exists.
  static Future<Map<String, String>?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null || token.isEmpty) return null;
    
    // If they have a session, flag the device as having registered
    await prefs.setBool(_keyHasRegistered, true);
    
    return {
      'token': token,
      'userName': prefs.getString(_keyUserName) ?? '',
      'userEmail': prefs.getString(_keyUserEmail) ?? '',
      'userPhone': prefs.getString(_keyUserPhone) ?? '',
      'userRole': prefs.getString(_keyUserRole) ?? 'user',
    };
  }

  /// Clear session on logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserPhone);
    await prefs.remove(_keyUserRole);
  }

  /// Check if a session exists
  static Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    return token != null && token.isNotEmpty;
  }

  static const _keyHasRegistered = 'device_has_registered';

  /// Mark device as having registered/logged in at least once
  static Future<void> setDeviceHasRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasRegistered, true);
  }

  /// Check if this device has ever registered/logged in
  static Future<bool> hasDeviceRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasRegistered) ?? false;
  }
}
