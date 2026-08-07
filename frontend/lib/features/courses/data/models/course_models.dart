class Category {
  final String id;
  final String name;
  final String description;
  final int courseCount;
  final String colorHex;
  final String icon;

  const Category({
    required this.id,
    required this.name,
    required this.description,
    required this.courseCount,
    required this.colorHex,
    required this.icon,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      courseCount: map['course_count'] as int? ?? 0,
      colorHex: map['color_hex'] as String? ?? '#1565C0',
      icon: map['icon'] as String? ?? 'school',
    );
  }
}

class Course {
  final String id;
  final String categoryId;
  final String title;
  final String description;
  final String instructorName;
  final String? thumbnailUrl;
  final int totalChapters;
  final double price;
  final bool isFree;
  final String createdAt;

  const Course({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.instructorName,
    this.thumbnailUrl,
    required this.totalChapters,
    required this.price,
    required this.isFree,
    required this.createdAt,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String? ?? '',
      categoryId: map['category_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      instructorName: map['instructor_name'] as String? ?? '',
      thumbnailUrl: map['thumbnail_url'] as String?,
      totalChapters: map['total_chapters'] as int? ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      isFree: map['is_free'] as bool? ?? false,
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}

class Chapter {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final int chapterNumber;
  final int durationSeconds;
  final String? videoUrl;
  final bool isFree;
  // Runtime fields set from client
  bool isCompleted;
  bool isUnlocked;
  int watchedSeconds;

  Chapter({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.chapterNumber,
    required this.durationSeconds,
    this.videoUrl,
    required this.isFree,
    this.isCompleted = false,
    this.isUnlocked = false,
    this.watchedSeconds = 0,
  });

  String get durationFormatted {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      id: map['id'] as String? ?? '',
      courseId: map['course_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      chapterNumber: map['chapter_number'] as int? ?? 0,
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      videoUrl: map['video_url'] as String?,
      isFree: map['is_free'] as bool? ?? false,
    );
  }
}

class Enrollment {
  final String id;
  final String studentId;
  final String courseId;
  final int progressPercent;
  final String? lastChapterId;
  final String enrolledAt;
  // Joined fields
  final Course? course;

  const Enrollment({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.progressPercent,
    this.lastChapterId,
    required this.enrolledAt,
    this.course,
  });

  factory Enrollment.fromMap(Map<String, dynamic> map) {
    return Enrollment(
      id: map['id'] as String? ?? '',
      studentId: map['student_id'] as String? ?? '',
      courseId: map['course_id'] as String? ?? '',
      progressPercent: map['progress_percent'] as int? ?? 0,
      lastChapterId: map['last_chapter_id'] as String?,
      enrolledAt: map['enrolled_at'] as String? ?? '',
      course: map['courses'] != null ? Course.fromMap(map['courses'] as Map<String, dynamic>) : null,
    );
  }
}
