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
import '../services/session_service.dart';

/// CourseService fetches course and category data from the EthioClass Go backend,
/// which in turn queries Supabase (so we don't expose Supabase keys in Flutter).
class CourseService {
  static const String _baseUrl = apiBaseUrl;

  // Cache for instant loading
  static final Map<String, List<Chapter>> _chaptersCache = {};

  /// Fetches all categories from the backend.
  Future<List<Category>> getCategories() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/categories'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetches divisions, optionally filtered by categoryId.
  Future<List<Division>> getDivisions({String? categoryId}) async {
    try {
      final uri = categoryId != null
          ? Uri.parse('$_baseUrl/divisions?category_id=$categoryId')
          : Uri.parse('$_baseUrl/divisions');

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => Division.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetches all courses from the backend, optionally filtered by divisionId or categoryId.
  Future<void> enrollCourse(String courseId) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/courses/$courseId/enroll'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to enroll in course');
    }
  }

  Future<List<Course>> getCourses({
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
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => Course.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetches chapters for a specific course (cached for instant loading).
  Future<List<Chapter>> getChapters(String courseId) async {
    if (_chaptersCache.containsKey(courseId)) {
      return _chaptersCache[courseId]!;
    }
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/chapters?course_id=$courseId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        final chapters = data
            .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
            .toList();
        _chaptersCache[courseId] = chapters;
        return chapters;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Returns cached chapters instantly (null if not yet fetched).
  List<Chapter>? getCachedChapters(String courseId) {
    return _chaptersCache[courseId];
  }

  /// Pre-fetches chapters for all courses in the background.
  void prefetchChapters(List<Course> courses) {
    for (final course in courses) {
      if (!_chaptersCache.containsKey(course.id)) {
        getChapters(course.id);
      }
    }
  }

  /// Fetches lessons for a specific chapter.
  Future<List<Lesson>> getLessons(String chapterId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/lessons?chapter_id=$chapterId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetches lesson materials for a specific lesson.
  Future<List<LessonMaterial>> getLessonMaterials(String lessonId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/lesson-materials?lesson_id=$lessonId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => LessonMaterial.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetches questions for a specific lesson.
  Future<List<Question>> getQuestions(String lessonId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/questions?lesson_id=$lessonId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
