import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/lesson_model.dart';

class MiniPlayerService extends ChangeNotifier {
  static final MiniPlayerService instance = MiniPlayerService._();
  MiniPlayerService._();

  Lesson? _lesson;
  String? _courseTitle;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isMinimized = false;

  Lesson? get lesson => _lesson;
  String? get courseTitle => _courseTitle;
  VideoPlayerController? get videoController => _videoController;
  ChewieController? get chewieController => _chewieController;
  bool get isMinimized => _isMinimized;
  bool get isActive => _lesson != null && _videoController != null;

  bool hasActiveLesson(String lessonId) {
    return _lesson?.id == lessonId && _videoController != null;
  }

  void handover({
    required Lesson lesson,
    required String courseTitle,
    required VideoPlayerController videoController,
    required ChewieController chewieController,
  }) {
    _lesson = lesson;
    _courseTitle = courseTitle;
    _videoController = videoController;
    _chewieController = chewieController;
    _isMinimized = false;
  }

  void minimize() {
    _isMinimized = true;
    notifyListeners();
  }

  void expand() {
    _isMinimized = false;
    notifyListeners();
  }

  void close() {
    _chewieController?.pause();
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
    _lesson = null;
    _courseTitle = null;
    _isMinimized = false;
    notifyListeners();
  }
}
