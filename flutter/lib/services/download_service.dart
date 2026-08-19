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
    if (_cancelTokens.containsKey(lesson.id)) return; // Already running

    final cancelToken = CancelToken();
    _cancelTokens[lesson.id] = cancelToken;

    final notifier = ValueNotifier<double>(0.0);
    progressNotifiers[lesson.id] = notifier;

    void reportProgress(double p) {
      notifier.value = p;
      onProgress(p);
    }

    // Helper for robust downloading with auto-retry
    Future<int> downloadWithRetry(String url, String localPath, double progressStart, double progressWeight) async {
      final file = File(localPath);
      int maxRetries = 10;
      int retries = 0;
      int finalSize = 0;
      
      while (retries < maxRetries) {
        if (cancelToken.isCancelled) return finalSize;
        
        int existingBytes = 0;
        if (await file.exists()) {
          existingBytes = await file.length();
        }

        try {
          final response = await _dio.get<ResponseBody>(
            url,
            cancelToken: cancelToken,
            options: Options(
              headers: existingBytes > 0 ? {'Range': 'bytes=$existingBytes-'} : null,
              responseType: ResponseType.stream,
            ),
          );
          
          if (response.statusCode == 416) {
            // Range not satisfiable -> file already complete!
            finalSize = existingBytes;
            return finalSize;
          }

          final sink = file.openWrite(mode: FileMode.append);
          int received = 0;
          final clHeader = response.headers.value('content-length');
          final totalRemaining = clHeader != null ? (int.tryParse(clHeader) ?? 0) : 0;
          
          await response.data!.stream.listen((chunk) {
            sink.add(chunk);
            received += chunk.length;
            final actualReceived = existingBytes + received;
            final actualTotal = existingBytes + (totalRemaining > 0 ? totalRemaining : received + 1);
            final localProgress = (actualReceived / actualTotal).clamp(0.0, 1.0);
            reportProgress(progressStart + (localProgress * progressWeight));
          }).asFuture();
          
          await sink.close();
          finalSize = existingBytes + received;
          return finalSize; // Success!
          
        } on DioException catch (e) {
          if (CancelToken.isCancel(e)) return finalSize;
          retries++;
          if (retries >= maxRetries) rethrow;
          await Future.delayed(const Duration(seconds: 2)); // Wait before retry
        } catch (e) {
          retries++;
          if (retries >= maxRetries) rethrow;
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      return finalSize;
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
        totalSize += await downloadWithRetry(videoUrl, localVideoPath, 0.0, 0.85);
      }

      // 2. Download Notes
      if (lesson.notesUrl != null && lesson.notesUrl!.isNotEmpty) {
        final notesUrl = '$apiBaseUrl/media/${lesson.notesUrl!}';
        localNotesPath = '${dir.path}/${lesson.id}_notes.pdf';
        totalSize += await downloadWithRetry(notesUrl, localNotesPath, 0.85, 0.14);
      }

      // 3. Cache Quiz
      String? cachedQuizJson;
      try {
        final quizResponse = await http.get(Uri.parse('$apiBaseUrl/quizzes?lesson_id=${lesson.id}'));
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
        await prefs.setString(_storageKey, jsonEncode(lessons.map((e) => e.toJson()).toList()));
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
      final nocache = '?t=${DateTime.now().millisecondsSinceEpoch}';
      if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
        final url = '$apiBaseUrl/media/${lesson.videoUrl!}$nocache';
        final response = await http.head(Uri.parse(url));
        final cl = response.headers['content-length'];
        if (cl != null) totalBytes += int.tryParse(cl) ?? 0;
      }
      if (lesson.notesUrl != null && lesson.notesUrl!.isNotEmpty) {
        final url = '$apiBaseUrl/media/${lesson.notesUrl!}$nocache';
        final response = await http.head(Uri.parse(url));
        final cl = response.headers['content-length'];
        if (cl != null) totalBytes += int.tryParse(cl) ?? 0;
      }
    } catch (_) {}
    return totalBytes;
  }
}
