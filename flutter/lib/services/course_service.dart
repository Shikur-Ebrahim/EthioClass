import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/category_model.dart';
import '../models/course_model.dart';

/// CourseService fetches course and category data from the EthioClass Go backend,
/// which in turn queries Supabase (so we don't expose Supabase keys in Flutter).
class CourseService {
  static const String _baseUrl = apiBaseUrl;

  // Sample fallback data shown while the backend is being deployed
  static final List<Category> _sampleCategories = [
    Category(
      id: 'sample-1',
      name: 'Grade 12',
      description: 'Courses for Grade 12 students',
      imageUrl: null,
    ),
    Category(
      id: 'sample-2',
      name: 'Freshman',
      description: 'Courses for high school scenario',
      imageUrl: null,
    ),
    Category(
      id: 'sample-3',
      name: 'TVET',
      description: 'Courses for good skill',
      imageUrl: null,
    ),
  ];

  static final List<Course> _sampleCourses = [
    Course(
      id: 'sample-c1',
      title: 'Mathematics Grade 12',
      description: 'Chapter 3: Derivatives and more',
      thumbnailUrl: null,
    ),
    Course(
      id: 'sample-c2',
      title: 'Chemistry Grade 12',
      description: 'Chapter 2: Acids and Bases',
      thumbnailUrl: null,
    ),
    Course(
      id: 'sample-c3',
      title: 'Electrical Installation',
      description: 'Module 1: Introduction to wiring',
      thumbnailUrl: null,
    ),
  ];

  /// Fetches all categories from the backend. Falls back to sample data on error.
  Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        if (data.isEmpty) return _sampleCategories;
        return data
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return _sampleCategories;
    } catch (_) {
      // Backend not yet deployed — return sample data
      return _sampleCategories;
    }
  }

  /// Fetches all courses from the backend. Falls back to sample data on error.
  Future<List<Course>> getCourses() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/courses'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        if (data.isEmpty) return _sampleCourses;
        return data
            .map((e) => Course.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return _sampleCourses;
    } catch (_) {
      // Backend not yet deployed — return sample data
      return _sampleCourses;
    }
  }
}
