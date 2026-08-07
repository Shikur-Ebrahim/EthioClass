class UserProfile {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String avatarUrl;
  final String role; // 'student' | 'admin'
  final String createdAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.avatarUrl,
    required this.role,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isStudent => role == 'student';

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      phoneNumber: map['phone_number'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String? ?? '',
      role: map['role'] as String? ?? 'student',
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'role': role,
      'created_at': createdAt,
    };
  }
}
