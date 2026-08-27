import 'dart:convert';

class Course {
  final String id;
  final String? categoryId; // Replaced divisionId with categoryId
  final String? categoryName;
  final String title;
  final String description;
  final String aboutText;
  final List<String> aboutBullets;
  final String instructorName;
  final String instructorPhone;
  final String? thumbnailUrl;
  final DateTime? createdAt;
  
  final int lessonCount;
  final int durationMinutes;
  final int studentCount;
  final int price;

  Course({
    required this.id,
    this.categoryId,
    this.categoryName,
    required this.title,
    required this.description,
    this.aboutText = '',
    this.aboutBullets = const [],
    this.instructorName = '',
    this.instructorPhone = '',
    this.thumbnailUrl,
    this.createdAt,
    this.lessonCount = 0,
    this.durationMinutes = 0,
    this.studentCount = 0,
    this.price = 249,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    List<String> parsedBullets = [];
    if (json['about_bullets'] != null) {
      try {
        final List<dynamic> decoded = jsonDecode(json['about_bullets'] as String);
        parsedBullets = decoded.map((e) => e.toString()).toList();
      } catch (e) {
        // Handle parsing error
      }
    }

    return Course(
      id: json['id'] as String,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      aboutText: json['about_text'] as String? ?? '',
      aboutBullets: parsedBullets,
      instructorName: json['instructor_name'] as String? ?? '',
      instructorPhone: json['instructor_phone'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      lessonCount: json['lesson_count'] as int? ?? 0,
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      studentCount: json['student_count'] as int? ?? 0,
      price: json['price'] as int? ?? 249,
    );
  }
}
