import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/category_model.dart';
import '../models/chapter_model.dart';
import '../models/course_model.dart';
import '../models/division_model.dart';
import '../models/lesson_model.dart';
import '../models/lesson_material_model.dart';
import '../models/question_model.dart';
import '../services/offline_cache_service.dart';
import '../services/session_service.dart';

/// CourseService - cache-first with full offline support.
/// All data is saved to disk on first online open and served from
/// disk on subsequent opens (online or offline).
class CourseService {
  static const String _baseUrl = apiBaseUrl;

  // In-memory cache for speed (cleared on hot restart)
  static final Map<String, List<Chapter>> _chaptersCache = {};

  // ── Categories ──────────────────────────────────────────────────────────────
  Future<List<Category>> getCategories() async {
    // 1. Try disk cache first
    final disk = await OfflineCacheService.instance.loadCategories();
    if (disk != null && disk.isNotEmpty) {
      // Return disk cache immediately, then refresh in background
      refreshCategories();
      return disk.map((e) => Category.fromJson(e)).toList();
    }
    // 2. No cache — fetch from network
    return refreshCategories();
  }

  Future<List<Category>> refreshCategories() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/categories'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        final rawMaps = list.cast<Map<String, dynamic>>();
        await OfflineCacheService.instance.saveCategories(rawMaps);
        return rawMaps.map((e) => Category.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ── Courses ──────────────────────────────────────────────────────────────────
  Future<List<Course>> getCourses({
    String? divisionId,
    String? categoryId,
  }) async {
    // For filtered queries, fetch from network only (or cache by key if needed)
    if (divisionId != null || categoryId != null) {
      return _fetchCourses(divisionId: divisionId, categoryId: categoryId);
    }
    // Unfiltered: disk-cache-first
    final disk = await OfflineCacheService.instance.loadCourses();
    if (disk != null && disk.isNotEmpty) {
      refreshCourses();
      return disk.map((e) => Course.fromJson(e)).toList();
    }
    return refreshCourses();
  }

  Future<List<Course>> refreshCourses() async {
    return _fetchCourses();
  }

  Future<List<Course>> _fetchCourses({
    String? divisionId,
    String? categoryId,
  }) async {
    try {
      Uri uri;
      if (divisionId != null) {
        uri = Uri.parse('$_baseUrl/courses?division_id=$divisionId');
      } else if (categoryId != null) {
        uri = Uri.parse('$_baseUrl/courses?category_id=$categoryId');
      } else {
        uri = Uri.parse('$_baseUrl/courses');
      }
      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        final rawMaps = list.cast<Map<String, dynamic>>();
        if (divisionId == null && categoryId == null) {
          await OfflineCacheService.instance.saveCourses(rawMaps);
        }
        return rawMaps.map((e) => Course.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ── Chapters ──────────────────────────────────────────────────────────────────
  Future<List<Chapter>> getChapters(String courseId) async {
    // 1. In-memory cache (fastest)
    if (_chaptersCache.containsKey(courseId)) {
      return _chaptersCache[courseId]!;
    }
    // 2. Disk cache
    final disk = await OfflineCacheService.instance.loadChapters(courseId);
    if (disk != null && disk.isNotEmpty) {
      final chapters = disk.map((e) => Chapter.fromJson(e)).toList();
      _chaptersCache[courseId] = chapters;
      refreshChapters(courseId); // refresh in background
      return chapters;
    }
    // 3. Network
    return refreshChapters(courseId);
  }

  Future<List<Chapter>> refreshChapters(String courseId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/chapters?course_id=$courseId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        final rawMaps = list.cast<Map<String, dynamic>>();
        await OfflineCacheService.instance.saveChapters(courseId, rawMaps);
        final chapters = rawMaps.map((e) => Chapter.fromJson(e)).toList();
        _chaptersCache[courseId] = chapters;
        return chapters;
      }
    } catch (_) {}
    return _chaptersCache[courseId] ?? [];
  }

  List<Chapter>? getCachedChapters(String courseId) => _chaptersCache[courseId];

  void prefetchChapters(List<Course> courses) {
    for (final course in courses) {
      if (!_chaptersCache.containsKey(course.id)) getChapters(course.id);
    }
  }

  // ── Lessons ──────────────────────────────────────────────────────────────────
  Future<List<Lesson>> getLessons(String chapterId) async {
    // Disk cache first
    final disk = await OfflineCacheService.instance.loadLessons(chapterId);
    if (disk != null && disk.isNotEmpty) {
      _refreshLessons(chapterId);
      return disk.map((e) => Lesson.fromJson(e)).toList();
    }
    return _refreshLessons(chapterId);
  }

  Future<List<Lesson>> _refreshLessons(String chapterId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/lessons?chapter_id=$chapterId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        final rawMaps = list.cast<Map<String, dynamic>>();
        await OfflineCacheService.instance.saveLessons(chapterId, rawMaps);
        return rawMaps.map((e) => Lesson.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ── Divisions ──────────────────────────────────────────────────────────────
  Future<List<Division>> getDivisions({String? categoryId}) async {
    try {
      final uri = categoryId != null
          ? Uri.parse('$_baseUrl/divisions?category_id=$categoryId')
          : Uri.parse('$_baseUrl/divisions');
      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list
            .cast<Map<String, dynamic>>()
            .map((e) => Division.fromJson(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // ── Enroll ─────────────────────────────────────────────────────────────────
  Future<void> enrollCourse(String courseId) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/courses/$courseId/enroll'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to enroll in course');
    }
  }

  // ── Lesson Materials ────────────────────────────────────────────────────────
  Future<List<LessonMaterial>> getLessonMaterials(String lessonId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/lesson-materials?lesson_id=$lessonId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list
            .cast<Map<String, dynamic>>()
            .map((e) => LessonMaterial.fromJson(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // ── Questions ───────────────────────────────────────────────────────────────
  Future<List<Question>> getQuestions(String lessonId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/questions?lesson_id=$lessonId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list
            .cast<Map<String, dynamic>>()
            .map((e) => Question.fromJson(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
