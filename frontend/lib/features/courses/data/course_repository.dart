import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/course_models.dart';

class CourseRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch all categories
  Future<List<Category>> fetchCategories() async {
    final data = await _client.from('categories').select().order('name');
    return (data as List).map((e) => Category.fromMap(e)).toList();
  }

  // Fetch all courses (optionally filtered by category)
  Future<List<Course>> fetchCourses({String? categoryId}) async {
    var query = _client.from('courses').select();
    if (categoryId != null) {
      query = query.eq('category_id', categoryId) as dynamic;
    }
    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => Course.fromMap(e)).toList();
  }

  // Fetch a single course by ID
  Future<Course> fetchCourse(String courseId) async {
    final data = await _client.from('courses').select().eq('id', courseId).single();
    return Course.fromMap(data);
  }

  // Fetch chapters for a course
  Future<List<Chapter>> fetchChapters(String courseId) async {
    final data = await _client
        .from('chapters')
        .select()
        .eq('course_id', courseId)
        .order('chapter_number');
    return (data as List).map((e) => Chapter.fromMap(e)).toList();
  }

  // Fetch enrolled courses for the current student
  Future<List<Enrollment>> fetchMyEnrollments() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('enrollments')
        .select('*, courses(*)')
        .eq('student_id', userId)
        .order('enrolled_at', ascending: false);

    return (data as List).map((e) => Enrollment.fromMap(e)).toList();
  }

  // Enroll in a course
  Future<void> enrollInCourse(String courseId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('enrollments').upsert({
      'student_id': userId,
      'course_id': courseId,
      'progress_percent': 0,
    });
  }

  // Check which chapters the student has unlocked
  Future<List<String>> fetchUnlockedChapterIds(String courseId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('chapter_unlocks')
        .select('chapter_id')
        .eq('student_id', userId);

    return (data as List).map((e) => e['chapter_id'] as String).toList();
  }

  // Check chapter progress for a course
  Future<List<Map<String, dynamic>>> fetchChapterProgress(String courseId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('chapter_progress')
        .select()
        .eq('student_id', userId)
        .eq('course_id', courseId);

    return (data as List).cast<Map<String, dynamic>>();
  }

  // Unlock a chapter (after payment)
  Future<void> unlockChapter(String chapterId, {String? paymentRef}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('chapter_unlocks').upsert({
      'student_id': userId,
      'chapter_id': chapterId,
      'payment_reference': paymentRef,
    });
  }

  // Update chapter progress
  Future<void> updateProgress({
    required String courseId,
    required String chapterId,
    required int watchedSeconds,
    required bool isCompleted,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('chapter_progress').upsert({
      'student_id': userId,
      'chapter_id': chapterId,
      'course_id': courseId,
      'watched_seconds': watchedSeconds,
      'is_completed': isCompleted,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Update overall course progress
    if (isCompleted) {
      final chapters = await fetchChapters(courseId);
      final progress = await fetchChapterProgress(courseId);
      final completedCount = progress.where((p) => p['is_completed'] == true).length;
      final percent = chapters.isEmpty ? 0 : ((completedCount / chapters.length) * 100).round();

      await _client.from('enrollments').upsert({
        'student_id': userId,
        'course_id': courseId,
        'progress_percent': percent,
        'last_chapter_id': chapterId,
      });
    }
  }
}
