import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme.dart';
import '../../models/guidance_video.dart';
import '../../config/api_config.dart';

class GuidanceVideoPlayer extends StatefulWidget {
  final GuidanceVideo video;
  final bool isPlaying;

  const GuidanceVideoPlayer({
    super.key,
    required this.video,
    required this.isPlaying,
  });

  @override
  State<GuidanceVideoPlayer> createState() => _GuidanceVideoPlayerState();
}

class _GuidanceVideoPlayerState extends State<GuidanceVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final String fullUrl = widget.video.videoUrl.startsWith('http') 
          ? widget.video.videoUrl 
          : '$apiBaseUrl/media/${widget.video.videoUrl}';
          
      _controller = VideoPlayerController.networkUrl(Uri.parse(fullUrl));
      await _controller.initialize();
      _controller.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (widget.isPlaying) {
          _controller.play();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void didUpdateWidget(GuidanceVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isInitialized) {
      if (widget.isPlaying && !oldWidget.isPlaying) {
        _controller.play();
      } else if (!widget.isPlaying && oldWidget.isPlaying) {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 48),
              SizedBox(height: 16),
              Text('Failed to load video', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isInitialized)
            GestureDetector(
              onTap: () {
                setState(() {
                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                });
              },
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          
          // Overlay UI
          Positioned(
            bottom: 20,
            left: 16,
            right: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 12,
                      child: Text(
                        '${widget.video.orderIndex}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.video.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.video.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.video.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // Play/Pause indicator
          if (_isInitialized && !_controller.value.isPlaying)
            const Center(
              child: Icon(Icons.play_arrow_rounded, color: Colors.white54, size: 80),
            ),
        ],
      ),
    );
  }
}
