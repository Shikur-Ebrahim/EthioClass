class Chapter {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final int chapterNumber;
  final bool isFree;
  final String? createdAt;

  Chapter({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.chapterNumber,
    required this.isFree,
    this.createdAt,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'],
      courseId: json['course_id'],
      title: json['title'],
      description: json['description'],
      thumbnailUrl: json['thumbnail_url'],
      chapterNumber: json['chapter_number'] ?? 1,
      isFree: json['is_free'] ?? false,
      createdAt: json['created_at'],
    );
  }
}
