class UserSettings {
  final String theme;
  final String downloadQuality;
  final bool pushNotifications;
  final bool emailNotifications;
  final String language;

  UserSettings({
    this.theme = 'system',
    this.downloadQuality = '720p',
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.language = 'en',
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      theme: json['theme'] ?? 'system',
      downloadQuality: json['downloadQuality'] ?? '720p',
      pushNotifications: json['pushNotifications'] ?? true,
      emailNotifications: json['emailNotifications'] ?? true,
      language: json['language'] ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'downloadQuality': downloadQuality,
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'language': language,
    };
  }

  UserSettings copyWith({
    String? theme,
    String? downloadQuality,
    bool? pushNotifications,
    bool? emailNotifications,
    String? language,
  }) {
    return UserSettings(
      theme: theme ?? this.theme,
      downloadQuality: downloadQuality ?? this.downloadQuality,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      language: language ?? this.language,
    );
  }
}
