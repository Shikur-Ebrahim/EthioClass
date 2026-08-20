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
    return progress > 1.0 ? 1.0 : progress; // Clamp to 1.0 max
  }
}
