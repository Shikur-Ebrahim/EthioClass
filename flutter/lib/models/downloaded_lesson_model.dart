import 'dart:convert';
import 'lesson_model.dart';

class DownloadedLesson {
  final Lesson lesson;
  final String courseTitle;
  final String chapterTitle;
  final String? courseThumbnailUrl;
  final String localVideoPath;
  final String? localNotesPath;
  final String? cachedQuizJson;
  final int sizeBytes;
  final DateTime downloadedAt;
  final int courseTotalLessons;

  DownloadedLesson({
    required this.lesson,
    required this.courseTitle,
    required this.chapterTitle,
    this.courseThumbnailUrl,
    required this.localVideoPath,
    this.localNotesPath,
    this.cachedQuizJson,
    required this.sizeBytes,
    required this.downloadedAt,
    this.courseTotalLessons = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'lesson': lesson.toJson(),
      'courseTitle': courseTitle,
      'chapterTitle': chapterTitle,
      'localVideoPath': localVideoPath,
      'localNotesPath': localNotesPath,
      'cachedQuizJson': cachedQuizJson,
      'sizeBytes': sizeBytes,
      'downloadedAt': downloadedAt.toIso8601String(),
      'courseThumbnailUrl': courseThumbnailUrl,
      'courseTotalLessons': courseTotalLessons,
    };
  }

  factory DownloadedLesson.fromJson(Map<String, dynamic> json) {
    return DownloadedLesson(
      lesson: Lesson.fromJson(json['lesson'] as Map<String, dynamic>),
      courseTitle: json['courseTitle'] ?? 'Course',
      chapterTitle: json['chapterTitle'] ?? json['courseTitle'] ?? 'Chapter',
      courseThumbnailUrl: json['courseThumbnailUrl'] as String?,
      localVideoPath: json['localVideoPath'] as String? ?? '',
      localNotesPath: json['localNotesPath'] as String?,
      cachedQuizJson: json['cachedQuizJson'] as String?,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      downloadedAt: json['downloadedAt'] != null 
          ? DateTime.parse(json['downloadedAt'] as String) 
          : DateTime.now(),
      courseTotalLessons: json['courseTotalLessons'] as int? ?? 1,
    );
  }
}
