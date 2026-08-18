import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson_model.dart';
import '../models/downloaded_lesson_model.dart';
import '../config/api_config.dart';

class DownloadService {
  static const String _storageKey = 'downloaded_lessons';
  final Dio _dio = Dio();

  // Singleton pattern
  DownloadService._privateConstructor();
  static final DownloadService instance = DownloadService._privateConstructor();

  Future<List<DownloadedLesson>> getDownloadedLessons() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => DownloadedLesson.fromJson(json)).toList();
  }

  Future<bool> isLessonDownloaded(String lessonId) async {
    final lessons = await getDownloadedLessons();
    return lessons.any((l) => l.lesson.id == lessonId);
  }

  Future<DownloadedLesson?> getDownloadedLesson(String lessonId) async {
    final lessons = await getDownloadedLessons();
    try {
      return lessons.firstWhere((l) => l.lesson.id == lessonId);
    } catch (e) {
      return null;
    }
  }

  Future<void> downloadLesson({
    required Lesson lesson,
    required String courseTitle,
    required String chapterTitle,
    required Function(double) onProgress,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      
      String? localVideoPath;
      String? localNotesPath;
      int totalSize = 0;
      
      // 1. Download Video
      if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
        final videoUrl = '$apiBaseUrl/media/${lesson.videoUrl!}';
        localVideoPath = '${dir.path}/${lesson.id}_video.mp4';
        
        await _dio.download(
          videoUrl,
          localVideoPath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              // Video represents 80% of total progress visually
              onProgress((received / total) * 0.8);
            }
          },
        );
        final file = File(localVideoPath);
        if (await file.exists()) {
          totalSize += await file.length();
        }
      }

      // 2. Download Notes
      if (lesson.notesUrl != null && lesson.notesUrl!.isNotEmpty) {
        final notesUrl = '$apiBaseUrl/media/${lesson.notesUrl!}';
        localNotesPath = '${dir.path}/${lesson.id}_notes.pdf';
        
        await _dio.download(
          notesUrl,
          localNotesPath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              // Notes represents next 10%
              onProgress(0.8 + (received / total) * 0.1);
            }
          },
        );
        final file = File(localNotesPath);
        if (await file.exists()) {
          totalSize += await file.length();
        }
      }

      // 3. Fetch and cache Quiz
      String? cachedQuizJson;
      try {
        final quizResponse = await http.get(Uri.parse('$apiBaseUrl/quizzes?lesson_id=${lesson.id}'));
        if (quizResponse.statusCode == 200) {
          cachedQuizJson = quizResponse.body;
        }
      } catch (_) {
        // Ignore quiz errors if there's no quiz
      }
      
      onProgress(1.0); // Complete

      if (localVideoPath != null) {
        final newDownload = DownloadedLesson(
          lesson: lesson,
          courseTitle: courseTitle,
          chapterTitle: chapterTitle,
          localVideoPath: localVideoPath,
          localNotesPath: localNotesPath,
          cachedQuizJson: cachedQuizJson,
          sizeBytes: totalSize,
          downloadedAt: DateTime.now(),
        );

        final prefs = await SharedPreferences.getInstance();
        final lessons = await getDownloadedLessons();
        
        // Remove if already exists to overwrite
        lessons.removeWhere((l) => l.lesson.id == lesson.id);
        lessons.add(newDownload);
        
        final String encodedData = jsonEncode(lessons.map((e) => e.toJson()).toList());
        await prefs.setString(_storageKey, encodedData);
      }
    } catch (e) {
      throw Exception('Failed to download lesson: $e');
    }
  }

  Future<void> deleteLesson(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final lessons = await getDownloadedLessons();
    
    final lessonToRemove = lessons.firstWhere((l) => l.lesson.id == lessonId, orElse: () => throw Exception('Not found'));
    
    // Delete files
    final videoFile = File(lessonToRemove.localVideoPath);
    if (await videoFile.exists()) await videoFile.delete();
    
    if (lessonToRemove.localNotesPath != null) {
      final notesFile = File(lessonToRemove.localNotesPath!);
      if (await notesFile.exists()) await notesFile.delete();
    }
    
    // Remove from prefs
    lessons.removeWhere((l) => l.lesson.id == lessonId);
    final String encodedData = jsonEncode(lessons.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encodedData);
  }

  Future<int> getLessonSize(Lesson lesson) async {
    int totalBytes = 0;
    try {
      if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
        final videoUrl = '$apiBaseUrl/media/${lesson.videoUrl!}';
        final response = await _dio.head(videoUrl);
        final length = response.headers.value(Headers.contentLengthHeader);
        if (length != null) {
          totalBytes += int.tryParse(length) ?? 0;
        }
      }
      if (lesson.notesUrl != null && lesson.notesUrl!.isNotEmpty) {
        final notesUrl = '$apiBaseUrl/media/${lesson.notesUrl!}';
        final response = await _dio.head(notesUrl);
        final length = response.headers.value(Headers.contentLengthHeader);
        if (length != null) {
          totalBytes += int.tryParse(length) ?? 0;
        }
      }
    } catch (_) {
      // Ignore errors for HEAD requests
    }
    return totalBytes;
  }
}

