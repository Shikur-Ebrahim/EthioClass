import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'my_learning_service.dart';

class ProgressService {
  static final ProgressService instance = ProgressService._internal();

  factory ProgressService() {
    return instance;
  }

  ProgressService._internal();

  SharedPreferences? _prefs;
  static const String _completedLessonsKey = 'completed_lessons_list';
  
  // Notifies listeners when progress changes
  final ValueNotifier<Set<String>> completedLessonsNotifier = ValueNotifier<Set<String>>({});

  Future<void> init() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    final savedList = _prefs!.getStringList(_completedLessonsKey) ?? [];
    completedLessonsNotifier.value = savedList.toSet();
  }

  bool isLessonCompleted(String lessonId) {
    return completedLessonsNotifier.value.contains(lessonId);
  }

  Future<void> markLessonComplete(String courseId, String lessonId) async {
    await init();
    final current = Set<String>.from(completedLessonsNotifier.value);
    if (!current.contains(lessonId)) {
      current.add(lessonId);
      completedLessonsNotifier.value = current;
      await _prefs!.setStringList(_completedLessonsKey, current.toList());
      
      // Increment course count
      final courseKey = 'course_completed_count_$courseId';
      final currentCount = _prefs!.getInt(courseKey) ?? 0;
      await _prefs!.setInt(courseKey, currentCount + 1);

      // Sync to backend (fire and forget – ignore errors)
      try {
        await MyLearningService.instance.markLessonProgress(
          courseId: courseId,
          lessonId: lessonId,
          completed: true,
        );
      } catch (_) {}
    }
  }

  Future<void> markLessonIncomplete(String courseId, String lessonId) async {
    await init();
    final current = Set<String>.from(completedLessonsNotifier.value);
    if (current.contains(lessonId)) {
      current.remove(lessonId);
      completedLessonsNotifier.value = current;
      await _prefs!.setStringList(_completedLessonsKey, current.toList());
      
      // Decrement course count
      final courseKey = 'course_completed_count_$courseId';
      final currentCount = _prefs!.getInt(courseKey) ?? 0;
      if (currentCount > 0) {
        await _prefs!.setInt(courseKey, currentCount - 1);
      }
    }
  }

  Future<void> toggleLessonCompletion(String courseId, String lessonId) async {
    if (isLessonCompleted(lessonId)) {
      await markLessonIncomplete(courseId, lessonId);
    } else {
      await markLessonComplete(courseId, lessonId);
    }
  }

  // Calculate course progress using the stored count and total course lesson count
  double calculateCourseProgress(String courseId, int totalCourseLessons) {
    if (totalCourseLessons == 0) return 0.0;
    if (_prefs == null) return 0.0;
    final courseKey = 'course_completed_count_$courseId';
    final completedCount = _prefs!.getInt(courseKey) ?? 0;
    double progress = completedCount / totalCourseLessons;
    return progress > 1.0 ? 1.0 : progress;
  }

  // ── Last Watched Tracking ──────────────────────────────────────

  /// Save the last lesson the user opened for a course.
  /// [lessonIndex] is the index within the lesson list of that chapter.
  Future<void> saveLastWatched({
    required String courseId,
    required String chapterId,
    required int lessonIndex,
  }) async {
    await init();
    await _prefs!.setString('last_chapter_$courseId', chapterId);
    await _prefs!.setInt('last_lesson_index_$courseId', lessonIndex);
    // Track globally to show in 'Continue Learning' section
    await _prefs!.setString('global_last_course_id', courseId);
  }

  /// Get the last watched position for a course.
  /// Returns a Map with 'chapterId' and 'lessonIndex', or null if never watched.
  Map<String, dynamic>? getLastWatched(String courseId) {
    if (_prefs == null) return null;
    final chapterId = _prefs!.getString('last_chapter_$courseId');
    if (chapterId == null) return null;
    final lessonIndex = _prefs!.getInt('last_lesson_index_$courseId') ?? 0;
    return {'chapterId': chapterId, 'lessonIndex': lessonIndex};
  }

  /// Get the ID of the course the user most recently interacted with.
  String? getGlobalLastWatchedCourseId() {
    if (_prefs == null) return null;
    return _prefs!.getString('global_last_course_id');
  }

  // ── Video Timestamp Tracking ──────────────────────────────────────
  
  /// Save the current playback timestamp (in seconds) for a specific lesson
  Future<void> saveVideoTimestamp(String lessonId, int seconds) async {
    await init();
    await _prefs!.setInt('video_timestamp_$lessonId', seconds);
  }

  /// Get the saved playback timestamp (in seconds) for a specific lesson
  int getVideoTimestamp(String lessonId) {
    if (_prefs == null) return 0;
    return _prefs!.getInt('video_timestamp_$lessonId') ?? 0;
  }

  // ── Download Continue Learning Tracking ───────────────────────────

  /// Save the last downloaded lesson the user opened
  Future<void> saveLastDownloadedLesson({
    required String courseTitle,
    required String chapterTitle,
    required String lessonId,
    required String lessonTitle,
    required int lessonIndex,
    required String courseThumbnailUrl,
  }) async {
    await init();
    await _prefs!.setString('dl_last_courseTitle', courseTitle);
    await _prefs!.setString('dl_last_chapterTitle', chapterTitle);
    await _prefs!.setString('dl_last_lessonId', lessonId);
    await _prefs!.setString('dl_last_lessonTitle', lessonTitle);
    await _prefs!.setInt('dl_last_lessonIndex', lessonIndex);
    await _prefs!.setString('dl_last_thumbUrl', courseThumbnailUrl);
  }

  /// Get the last downloaded lesson info, or null if none
  Map<String, dynamic>? getLastDownloadedLesson() {
    if (_prefs == null) return null;
    final courseTitle = _prefs!.getString('dl_last_courseTitle');
    if (courseTitle == null) return null;
    return {
      'courseTitle': courseTitle,
      'chapterTitle': _prefs!.getString('dl_last_chapterTitle') ?? '',
      'lessonId': _prefs!.getString('dl_last_lessonId') ?? '',
      'lessonTitle': _prefs!.getString('dl_last_lessonTitle') ?? '',
      'lessonIndex': _prefs!.getInt('dl_last_lessonIndex') ?? 0,
      'thumbUrl': _prefs!.getString('dl_last_thumbUrl') ?? '',
    };
  }
}
