import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/api_config.dart';

class BookmarkService {
  static final BookmarkService instance = BookmarkService._internal();
  static const String _baseUrl = apiBaseUrl;
  
  BookmarkService._internal();

  /// Gets a unique user ID for device (since we don't have full auth yet).
  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('device_user_id');
    if (userId == null) {
      userId = const Uuid().v4();
      await prefs.setString('device_user_id', userId);
    }
    return userId;
  }

  Future<void> addLessonBookmark({
    required String lessonId,
    required String courseId,
    required String chapterId,
  }) async {
    final userId = await _getUserId();
    final response = await http.post(
      Uri.parse('$_baseUrl/bookmarks/lessons'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'lesson_id': lessonId,
        'course_id': courseId,
        'chapter_id': chapterId,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add lesson bookmark');
    }
  }

  Future<void> removeLessonBookmark(String lessonId) async {
    final userId = await _getUserId();
    final response = await http.delete(
      Uri.parse('$_baseUrl/bookmarks/lessons/$lessonId?user_id=$userId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to remove lesson bookmark');
    }
  }

  Future<void> addCourseBookmark(String courseId) async {
    final userId = await _getUserId();
    final response = await http.post(
      Uri.parse('$_baseUrl/bookmarks/courses'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'course_id': courseId,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add course bookmark');
    }
  }

  Future<void> removeCourseBookmark(String courseId) async {
    final userId = await _getUserId();
    final response = await http.delete(
      Uri.parse('$_baseUrl/bookmarks/courses/$courseId?user_id=$userId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to remove course bookmark');
    }
  }

  Future<Map<String, dynamic>> getBookmarks() async {
    final userId = await _getUserId();
    final response = await http.get(
      Uri.parse('$_baseUrl/bookmarks?user_id=$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch bookmarks');
    }
  }
}
