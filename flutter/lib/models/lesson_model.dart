class Lesson {
  final String id;
  final String courseId;
  final String title;
  final String? thumbnailUrl;
  final int orderIndex;
  final String? createdAt;

  Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    this.thumbnailUrl,
    this.orderIndex = 0,
    this.createdAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      courseId: json['course_id'],
      title: json['title'],
      thumbnailUrl: json['thumbnail_url'],
      orderIndex: json['order_index'] ?? 0,
      createdAt: json['created_at'],
    );
  }
}
