import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/category_model.dart';
import '../models/course_model.dart';

/// CourseService fetches course and category data from the EthioClass Go backend,
/// which in turn queries Supabase (so we don't expose Supabase keys in Flutter).
class CourseService {
  static const String _baseUrl = apiBaseUrl;

  /// Fetches all categories from the backend.
  Future<List<Category>> getCategories() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/categories'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  /// Fetches all courses from the backend.
  Future<List<Course>> getCourses() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/courses'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load courses');
    }
  }
}
