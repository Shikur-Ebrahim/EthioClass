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
  });

  Map<String, dynamic> toJson() {
    return {
      'lesson': lesson.toJson(),
      'courseTitle': courseTitle,
      'chapterTitle': chapterTitle,
      'courseThumbnailUrl': courseThumbnailUrl,
      'localVideoPath': localVideoPath,
      'localNotesPath': localNotesPath,
      'cachedQuizJson': cachedQuizJson,
      'sizeBytes': sizeBytes,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }

  factory DownloadedLesson.fromJson(Map<String, dynamic> json) {
    return DownloadedLesson(
      lesson: Lesson.fromJson(json['lesson']),
      courseTitle: json['courseTitle'] ?? 'Course',
      chapterTitle: json['chapterTitle'] ?? json['courseTitle'] ?? 'Chapter', // fallback for old data
      courseThumbnailUrl: json['courseThumbnailUrl'],
      localVideoPath: json['localVideoPath'],
      localNotesPath: json['localNotesPath'],
      cachedQuizJson: json['cachedQuizJson'],
      sizeBytes: json['sizeBytes'] ?? 0,
      downloadedAt: DateTime.parse(json['downloadedAt']),
    );
  }
}

