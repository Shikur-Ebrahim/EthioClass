import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

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
}
