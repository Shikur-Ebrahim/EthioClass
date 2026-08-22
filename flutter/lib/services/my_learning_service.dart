import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class MyLearningCourse {
  final String id;
  final String title;
  final String? thumbnailUrl;
  final String instructorName;
  final int totalLessons;
  final int completedLessons;
  final double progress;
  final String? lastAccessedAt;
  final bool isCompleted;

  MyLearningCourse({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    required this.instructorName,
    required this.totalLessons,
    required this.completedLessons,
    required this.progress,
    this.lastAccessedAt,
    required this.isCompleted,
  });

  factory MyLearningCourse.fromJson(Map<String, dynamic> json) {
    return MyLearningCourse(
      id: json['id'] as String,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      instructorName: json['instructor_name'] as String? ?? '',
      totalLessons: (json['total_lessons'] as num?)?.toInt() ?? 0,
      completedLessons: (json['completed_lessons'] as num?)?.toInt() ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      lastAccessedAt: json['last_accessed_at'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }
}

class MyLearningService {
  static final MyLearningService instance = MyLearningService._internal();
  MyLearningService._internal();

  static const String _baseUrl = apiBaseUrl;

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('device_user_id') ?? '';
  }

  Future<Map<String, List<MyLearningCourse>>> getMyLearning() async {
    final userId = await _getUserId();
    if (userId.isEmpty) {
      return {'enrolled': [], 'saved': []};
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/my-learning?user_id=$userId'),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final enrolled = (data['enrolled'] as List? ?? [])
          .map((e) => MyLearningCourse.fromJson(e as Map<String, dynamic>))
          .toList();
      final saved = (data['saved'] as List? ?? [])
          .map((e) => MyLearningCourse.fromJson(e as Map<String, dynamic>))
          .toList();
      return {'enrolled': enrolled, 'saved': saved};
    } else {
      throw Exception('Failed to fetch My Learning data');
    }
  }

  Future<void> markLessonProgress({
    required String courseId,
    required String lessonId,
    required bool completed,
  }) async {
    final userId = await _getUserId();
    if (userId.isEmpty) return;
    await http.post(
      Uri.parse('$_baseUrl/lesson-progress'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'course_id': courseId,
        'lesson_id': lessonId,
        'completed': completed,
      }),
    ).timeout(const Duration(seconds: 10));
  }
}
