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
      if (rawUrl.startsWith('http')) {
        // Old full URLs (possibly wrong r2.dev format) — try to extract key and re-route
        // Pattern: if it contains 'r2.dev' extract the path after the domain
        final uri = Uri.tryParse(rawUrl);
        if (uri != null && rawUrl.contains('r2.dev')) {
          // Extract everything after the domain as the key
          final path = uri.path.replaceFirst('/', '');
          fullUrl = '$apiBaseUrl/media/$path';
        } else {
          fullUrl = rawUrl;
        }
      } else {
        // Relative key — serve via our backend media proxy
        fullUrl = '$apiBaseUrl/media/$rawUrl';
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
