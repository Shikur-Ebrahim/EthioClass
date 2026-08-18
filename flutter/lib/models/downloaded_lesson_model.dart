import 'dart:convert';
import 'lesson_model.dart';

class DownloadedLesson {
  final Lesson lesson;
  final String courseTitle;
  final String localVideoPath;
  final String? localNotesPath;
  final String? cachedQuizJson;
  final int sizeBytes;
  final DateTime downloadedAt;

  DownloadedLesson({
    required this.lesson,
    required this.courseTitle,
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
      courseTitle: json['courseTitle'] ?? '',
      localVideoPath: json['localVideoPath'],
      localNotesPath: json['localNotesPath'],
      cachedQuizJson: json['cachedQuizJson'],
      sizeBytes: json['sizeBytes'] ?? 0,
      downloadedAt: DateTime.parse(json['downloadedAt']),
    );
  }
}

