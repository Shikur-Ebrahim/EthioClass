import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists API JSON data to disk so the app works offline.
class OfflineCacheService {
  OfflineCacheService._();
  static final OfflineCacheService instance = OfflineCacheService._();

  static const _keyCategories = 'cache_categories';
  static const _keyCourses = 'cache_courses';
  static String _keyChapters(String courseId) => 'cache_chapters_$courseId';
  static String _keyLessons(String chapterId) => 'cache_lessons_$chapterId';

  Future<void> saveCategories(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCategories, jsonEncode(data));
  }

  Future<List<Map<String, dynamic>>?> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCategories);
    if (raw == null) return null;
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> saveCourses(List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCourses, jsonEncode(data));
  }

  Future<List<Map<String, dynamic>>?> loadCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCourses);
    if (raw == null) return null;
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> saveChapters(
    String courseId,
    List<Map<String, dynamic>> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyChapters(courseId), jsonEncode(data));
  }

  Future<List<Map<String, dynamic>>?> loadChapters(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyChapters(courseId));
    if (raw == null) return null;
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> saveLessons(
    String chapterId,
    List<Map<String, dynamic>> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLessons(chapterId), jsonEncode(data));
  }

  Future<List<Map<String, dynamic>>?> loadLessons(String chapterId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyLessons(chapterId));
    if (raw == null) return null;
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<bool> hasCache() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyCategories) || prefs.containsKey(_keyCourses);
  }
}
