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
  final Map<String, CancelToken> _cancelTokens = {};

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

  final Map<String, bool> _activeDownloads = {};

  void pauseDownload(String lessonId) {
    _activeDownloads[lessonId] = false;
  }

  void cancelDownload(String lessonId) {
    _activeDownloads[lessonId] = false;
    // We could also delete the partial file here if we wanted
  }

  Future<void> downloadLesson({
    required Lesson lesson,
    required String courseTitle,
    required String chapterTitle,
    String? courseThumbnailUrl,
    int courseTotalLessons = 1,
    required Function(double) onProgress,
  }) async {
    _activeDownloads[lesson.id] = true;
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
        
        int downloadedBytes = 0;
        if (await file.exists()) {
          downloadedBytes = await file.length();
        }

        final request = http.Request('GET', Uri.parse(videoUrl));
        if (downloadedBytes > 0) {
          request.headers['Range'] = 'bytes=$downloadedBytes-';
        }
        
        final response = await http.Client().send(request);
        
        // If range request is not supported, it might return 200 OK with full file.
        // We should handle that by resetting downloadedBytes to 0 and overwriting.
        var sinkMode = FileMode.append;
        if (response.statusCode == 200) {
          downloadedBytes = 0;
          sinkMode = FileMode.write;
        } else if (response.statusCode != 206) {
           throw Exception('Failed to download: HTTP ${response.statusCode}');
        }

        final totalBytes = downloadedBytes + (response.contentLength ?? 0);
        final sink = file.openWrite(mode: sinkMode);

        await for (final chunk in response.stream) {
          if (_activeDownloads[lesson.id] == false) {
            await sink.close();
            return; // Paused
          }
          sink.add(chunk);
          downloadedBytes += chunk.length;
          if (totalBytes > 0) {
            onProgress((downloadedBytes / totalBytes) * 0.8);
          }
        }
        await sink.close();
        totalSize += downloadedBytes;
      }

      // 2. Download Notes
      if (lesson.notesUrl != null && lesson.notesUrl!.isNotEmpty) {
        final notesUrl = '$apiBaseUrl/media/${lesson.notesUrl!}';
        localNotesPath = '${dir.path}/${lesson.id}_notes.pdf';
        final file = File(localNotesPath);
        
        int downloadedBytes = 0;
        if (await file.exists()) {
          downloadedBytes = await file.length();
        }

        final request = http.Request('GET', Uri.parse(notesUrl));
        if (downloadedBytes > 0) {
          request.headers['Range'] = 'bytes=$downloadedBytes-';
        }
        
        final response = await http.Client().send(request);
        
        var sinkMode = FileMode.append;
        if (response.statusCode == 200) {
          downloadedBytes = 0;
          sinkMode = FileMode.write;
        } else if (response.statusCode != 206) {
           throw Exception('Failed to download notes: HTTP ${response.statusCode}');
        }

        final totalBytes = downloadedBytes + (response.contentLength ?? 0);
        final sink = file.openWrite(mode: sinkMode);

        await for (final chunk in response.stream) {
          if (_activeDownloads[lesson.id] == false) {
            await sink.close();
            return; // Paused
          }
          sink.add(chunk);
          downloadedBytes += chunk.length;
          if (totalBytes > 0) {
            onProgress(0.8 + (downloadedBytes / totalBytes) * 0.1);
          }
        }
        await sink.close();
        totalSize += downloadedBytes;
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
        
        final String encodedData = jsonEncode(lessons.map((e) => e.toJson()).toList());
        await prefs.setString(_storageKey, encodedData);
      }
    } catch (e) {
      throw Exception('Failed to download lesson: $e');
    } finally {
      _activeDownloads.remove(lesson.id);
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
        final url = '$apiBaseUrl/media/${lesson.videoUrl!}';
        var response = await http.head(Uri.parse(url));
        var cl = response.headers['content-length'];
        if (cl != null && int.tryParse(cl) != null && int.parse(cl) > 0) {
          totalBytes += int.parse(cl);
        }
      }
      if (lesson.notesUrl != null && lesson.notesUrl!.isNotEmpty) {
        final url = '$apiBaseUrl/media/${lesson.notesUrl!}';
        var response = await http.head(Uri.parse(url));
        var cl = response.headers['content-length'];
        if (cl != null && int.tryParse(cl) != null && int.parse(cl) > 0) {
          totalBytes += int.parse(cl);
        }
      }
    } catch (_) {}
    return totalBytes;
  }
}

