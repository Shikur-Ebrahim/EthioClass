import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/course_repository.dart';
import '../../data/models/course_models.dart';

// Repository provider
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository();
});

// All categories
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(courseRepositoryProvider).fetchCategories();
});

// All courses
final coursesProvider = FutureProvider.family<List<Course>, String?>((ref, categoryId) async {
  return ref.read(courseRepositoryProvider).fetchCourses(categoryId: categoryId);
});

// Single course
final courseDetailProvider = FutureProvider.family<Course, String>((ref, courseId) async {
  return ref.read(courseRepositoryProvider).fetchCourse(courseId);
});

// My enrolled courses
final myEnrollmentsProvider = FutureProvider<List<Enrollment>>((ref) async {
  return ref.read(courseRepositoryProvider).fetchMyEnrollments();
});

// Continue learning — first enrollment with progress < 100
final continueLearningProvider = FutureProvider<Enrollment?>((ref) async {
  final enrollments = await ref.watch(myEnrollmentsProvider.future);
  if (enrollments.isEmpty) return null;
  // Return the first enrollment that is not yet 100% complete
  final ongoing = enrollments.where((e) => e.progressPercent < 100).toList();
  return ongoing.isNotEmpty ? ongoing.first : enrollments.first;
});

// Chapters for a course (with unlock/progress status merged in)
final chaptersProvider = FutureProvider.family<List<Chapter>, String>((ref, courseId) async {
  final repo = ref.read(courseRepositoryProvider);
  final chapters = await repo.fetchChapters(courseId);
  final unlockedIds = await repo.fetchUnlockedChapterIds(courseId);
  final progress = await repo.fetchChapterProgress(courseId);

  return chapters.map((ch) {
    final prog = progress.where((p) => p['chapter_id'] == ch.id).firstOrNull;
    ch.isCompleted = prog?['is_completed'] as bool? ?? false;
    ch.watchedSeconds = prog?['watched_seconds'] as int? ?? 0;
    ch.isUnlocked = ch.isFree || unlockedIds.contains(ch.id);
    return ch;
  }).toList();
});
