import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/course_model.dart';
import '../../services/course_service.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  late Future<List<Course>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = CourseService().getCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'All Courses',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<List<Course>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load courses.',
                  style: TextStyle(color: AppColors.error)),
            );
          }
          final courses = snapshot.data ?? [];
          if (courses.isEmpty) {
            return const Center(
              child: Text('No courses available yet.',
                  style: TextStyle(color: AppColors.grey)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) {
              final course = courses[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseDetailScreen(
                      course: course,
                      index: i,
                      categoryName: course.categoryName ?? 'Course',
                    ),
                  ),
                ),
                child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 56,
                      height: 56,
                      color: AppColors.navy,
                      child: course.thumbnailUrl != null
                          ? Image.network(course.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.play_circle_outline_rounded,
                                      color: Colors.white54, size: 28))
                          : const Icon(Icons.play_circle_outline_rounded,
                              color: Colors.white54, size: 28),
                    ),
                  ),
                  title: Text(
                    course.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.grey),
                ),
               ),
              );
            },
          );
        },
      ),
    );
  }
}
