import 'dart:convert';

class Question {
  final String id;
  final String lessonId;
  final String questionText;
  final String? questionImageUrl;
  final List<String> options;
  final int correctOptionIndex;
  final String? explanation;
  final String? createdAt;

  Question({
    required this.id,
    required this.lessonId,
    required this.questionText,
    this.questionImageUrl,
    required this.options,
    required this.correctOptionIndex,
    this.explanation,
    this.createdAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    List<String> parsedOptions = [];
    if (json['options'] != null) {
      if (json['options'] is String) {
        try {
          parsedOptions = List<String>.from(jsonDecode(json['options']));
        } catch (_) {}
      } else if (json['options'] is List) {
        parsedOptions = List<String>.from(json['options']);
      }
    }

    return Question(
      id: json['id'],
      lessonId: json['lesson_id'],
      questionText: json['question_text'],
      questionImageUrl: json['question_image_url'],
      options: parsedOptions,
      correctOptionIndex: json['correct_option_index'] ?? 0,
      explanation: json['explanation'],
      createdAt: json['created_at'],
    );
  }
}
