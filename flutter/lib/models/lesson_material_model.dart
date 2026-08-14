class LessonMaterial {
  final String id;
  final String lessonId;
  final String? videoUrl;
  final String? videoThumbnailUrl;
  final String? notesContent;
  final String? notesThumbnailUrl;
  final String? createdAt;

  LessonMaterial({
    required this.id,
    required this.lessonId,
    this.videoUrl,
    this.videoThumbnailUrl,
    this.notesContent,
    this.notesThumbnailUrl,
    this.createdAt,
  });

  factory LessonMaterial.fromJson(Map<String, dynamic> json) {
    return LessonMaterial(
      id: json['id'],
      lessonId: json['lesson_id'],
      videoUrl: json['video_url'],
      videoThumbnailUrl: json['video_thumbnail_url'],
      notesContent: json['notes_content'],
      notesThumbnailUrl: json['notes_thumbnail_url'],
      createdAt: json['created_at'],
    );
  }
}
