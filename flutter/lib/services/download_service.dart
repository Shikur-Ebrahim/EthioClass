import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lesson_model.dart';
import '../models/downloaded_lesson_model.dart';
import '../config/api_config.dart';

class DownloadService {
  static const String _storageKey = 'downloaded_lessons';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 30),
  ));

  DownloadService._privateConstructor();
  static final DownloadService instance = DownloadService._privateConstructor();

  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, ValueNotifier<double>> progressNotifiers = {};

  bool isDownloading(String lessonId) => _cancelTokens.containsKey(lessonId);

  void pauseDownload(String lessonId) {
    _cancelTokens[lessonId]?.cancel('paused');
    _cancelTokens.remove(lessonId);
    progressNotifiers[lessonId]?.dispose();
    progressNotifiers.remove(lessonId);
  }

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
    } catch (_) {
      return null;
    }
  }

  Future<void> downloadLesson({
    required Lesson lesson,
    required String courseTitle,
    required String chapterTitle,
    String? courseThumbnailUrl,
    int courseTotalLessons = 1,
    required Function(double) onProgress,
  }) async {
    if (_cancelTokens.containsKey(lesson.id)) return;

    final cancelToken = CancelToken();
    _cancelTokens[lesson.id] = cancelToken;
    final notifier = ValueNotifier<double>(0.0);
    progressNotifiers[lesson.id] = notifier;

    void reportProgress(double p) {
      notifier.value = p;
      onProgress(p);
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      String? localVideoPath;
      String? localNotesPath;
      int totalSize = 0;

      // 1. Download Video
      if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
        final videoUrl = '$apiBaseUrl/media/${lesson.videoUrl!}';
        localVideoPath = '${dir.path}/${lesson.id}_video.mp4';
        final file = File(localVideoPath);

        int existingBytes = 0;
        if (await file.exists()) {
          existingBytes = await file.length();
        }

        try {
          await _dio.download(
            videoUrl,
            localVideoPath,
            cancelToken: cancelToken,
            deleteOnError: false,
            appendData: existingBytes > 0,
            options: Options(
              headers: existingBytes > 0 ? {'Range': 'bytes=$existingBytes-'} : null,
            ),
            onReceiveProgress: (received, total) {
              final actualReceived = existingBytes + received;
              final actualTotal = total > 0 ? existingBytes + total : 0;
              final progress = actualTotal > 0
                  ? (actualReceived / actualTotal).clamp(0.0, 0.9)
                  : 0.05;
              reportProgress(progress);
            },
          );
        } on DioException catch (e) {
          if (CancelToken.isCancel(e)) return;
          rethrow;
        }

        if (await file.exists()) totalSize += await file.length();
      }

      // 2. Download Notes
      if (lesson.notesUrl != null && lesson.notesUrl!.isNotEmpty) {
        final notesUrl = '$apiBaseUrl/media/${lesson.notesUrl!}';
        localNotesPath = '${dir.path}/${lesson.id}_notes.pdf';
        final file = File(localNotesPath);

        int existingBytes = 0;
        if (await file.exists()) existingBytes = await file.length();

        try {
          await _dio.download(
            notesUrl,
            localNotesPath,
            cancelToken: cancelToken,
            deleteOnError: false,
            appendData: existingBytes > 0,
            options: Options(
              headers: existingBytes > 0 ? {'Range': 'bytes=$existingBytes-'} : null,
            ),
            onReceiveProgress: (received, total) {
              final actualReceived = existingBytes + received;
              final actualTotal = total > 0 ? existingBytes + total : 0;
              final noteProgress = actualTotal > 0
                  ? (actualReceived / actualTotal).clamp(0.0, 1.0) * 0.1
                  : 0.0;
              reportProgress((0.9 + noteProgress).clamp(0.0, 0.99));
            },
          );
        } on DioException catch (e) {
          if (CancelToken.isCancel(e)) return;
          rethrow;
        }

        if (await file.exists()) totalSize += await file.length();
      }

      // 3. Cache Quiz
      String? cachedQuizJson;
      try {
        final quizResponse =
            await http.get(Uri.parse('$apiBaseUrl/quizzes?lesson_id=${lesson.id}'));
        if (quizResponse.statusCode == 200) cachedQuizJson = quizResponse.body;
      } catch (_) {}

      reportProgress(1.0);

      // 4. Save record
      if (localVideoPath != null) {
        final newDownload = DownloadedLesson(
          lesson: lesson,
          courseTitle: courseTitle,
          chapterTitle: chapterTitle,
          courseThumbnailUrl: courseThumbnailUrl,
          courseTotalLessons: courseTotalLessons,
          localVideoPath: localVideoPath,
          localNotesPath: localNotesPath,
          cachedQuizJson: cachedQuizJson,
          sizeBytes: totalSize,
          downloadedAt: DateTime.now(),
        );

        final prefs = await SharedPreferences.getInstance();
        final lessons = await getDownloadedLessons();
        lessons.removeWhere((l) => l.lesson.id == lesson.id);
        lessons.add(newDownload);
        await prefs.setString(
            _storageKey, jsonEncode(lessons.map((e) => e.toJson()).toList()));
      }
    } catch (e) {
      throw Exception('Failed to download lesson: $e');
    } finally {
      _cancelTokens.remove(lesson.id);
      progressNotifiers[lesson.id]?.dispose();
      progressNotifiers.remove(lesson.id);
    }
  }

  Future<void> deleteLesson(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final lessons = await getDownloadedLessons();
    final lessonToRemove = lessons.firstWhere((l) => l.lesson.id == lessonId,
        orElse: () => throw Exception('Not found'));

    final videoFile = File(lessonToRemove.localVideoPath);
    if (await videoFile.exists()) await videoFile.delete();
    if (lessonToRemove.localNotesPath != null) {
      final notesFile = File(lessonToRemove.localNotesPath!);
      if (await notesFile.exists()) await notesFile.delete();
    }

    lessons.removeWhere((l) => l.lesson.id == lessonId);
    await prefs.setString(
        _storageKey, jsonEncode(lessons.map((e) => e.toJson()).toList()));
  }

  Future<int> getLessonSize(Lesson lesson) async {
    int totalBytes = 0;
    try {
      if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
        final url = '$apiBaseUrl/media/${lesson.videoUrl!}';
        final response = await http.head(Uri.parse(url));
        final cl = response.headers['content-length'];
        if (cl != null) totalBytes += int.tryParse(cl) ?? 0;
      }
      if (lesson.notesUrl != null && lesson.notesUrl!.isNotEmpty) {
        final url = '$apiBaseUrl/media/${lesson.notesUrl!}';
        final response = await http.head(Uri.parse(url));
        final cl = response.headers['content-length'];
        if (cl != null) totalBytes += int.tryParse(cl) ?? 0;
      }
    } catch (_) {}
    return totalBytes;
  }
}
