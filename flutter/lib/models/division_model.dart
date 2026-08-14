class Division {
  final String id;
  final String categoryId;
  final String name;
  final String? imageUrl;
  final String? createdAt;

  Division({
    required this.id,
    required this.categoryId,
    required this.name,
    this.imageUrl,
    this.createdAt,
  });

  factory Division.fromJson(Map<String, dynamic> json) {
    return Division(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      imageUrl: json['image_url'],
      createdAt: json['created_at'],
    );
  }
}
