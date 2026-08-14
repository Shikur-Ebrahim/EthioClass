class Course {
  final String id;
  final String? divisionId;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final DateTime? createdAt;

  Course({
    required this.id,
    this.divisionId,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      divisionId: json['division_id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
