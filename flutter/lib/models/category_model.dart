import '../config/api_config.dart';

class Category {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final DateTime? createdAt;

  Category({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    String? rawUrl = json['image_url'] as String?;
    String? fullUrl;
    if (rawUrl != null && rawUrl.isNotEmpty) {
      // If it's already a full URL, keep it; otherwise prepend the R2 public base URL
      if (rawUrl.startsWith('http')) {
        fullUrl = rawUrl;
      } else {
        fullUrl = '$r2PublicUrl/$rawUrl';
      }
    }
    return Category(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: fullUrl,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
