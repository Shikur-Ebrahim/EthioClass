class Lesson {
  final String id;
  final String chapterId;
  final String title;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? notesUrl;
  final int lessonNumber;
  final int durationMinutes;
  final String? createdAt;

  Lesson({
    required this.id,
    required this.chapterId,
    required this.title,
    this.thumbnailUrl,
    this.videoUrl,
    this.notesUrl,
    required this.lessonNumber,
    required this.durationMinutes,
    this.createdAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] ?? '',
      chapterId: json['chapter_id'] ?? '',
      title: json['title'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      videoUrl: json['video_url'],
      notesUrl: json['notes_url'],
      lessonNumber: json['lesson_number'] ?? 1,
      durationMinutes: json['duration_minutes'] ?? 0,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chapter_id': chapterId,
      'title': title,
      'thumbnail_url': thumbnailUrl,
      'video_url': videoUrl,
      'notes_url': notesUrl,
      'lesson_number': lessonNumber,
      'duration_minutes': durationMinutes,
      'created_at': createdAt,
    };
  }
}
