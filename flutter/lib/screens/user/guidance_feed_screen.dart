import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../models/guidance_video.dart';
import '../../widgets/guidance_video_player.dart';

class GuidanceFeedScreen extends StatefulWidget {
  final List<GuidanceVideo> videos;
  final int initialIndex;

  const GuidanceFeedScreen({
    super.key,
    required this.videos,
    required this.initialIndex,
  });

  @override
  State<GuidanceFeedScreen> createState() => _GuidanceFeedScreenState();
}

class _GuidanceFeedScreenState extends State<GuidanceFeedScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  bool _showOverlay = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _animation = Tween<double>(begin: 0.0, end: -60.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _checkAndShowOverlay();
  }
  
  Future<void> _checkAndShowOverlay() async {
    final prefs = await SharedPreferences.getInstance();
    int shownCount = prefs.getInt('guidance_feed_overlay_count') ?? 0;
    
    if (shownCount < 3) {
      if (mounted) {
        setState(() {
          _showOverlay = true;
        });
        _animationController.repeat(reverse: true);
        await prefs.setInt('guidance_feed_overlay_count', shownCount + 1);
      }
    }
  }

  void _dismissOverlay() {
    if (_showOverlay) {
      setState(() {
        _showOverlay = false;
      });
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.videos.length,
            onPageChanged: (index) {
              _dismissOverlay(); // Hide overlay when they figure out how to swipe
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GuidanceVideoPlayer(
                video: widget.videos[index],
                isPlaying: index == _currentIndex,
              );
            },
          ),
          
          // Swipe Gesture Overlay
          if (_showOverlay)
            GestureDetector(
              onTap: _dismissOverlay,
              onVerticalDragStart: (_) => _dismissOverlay(),
              child: Container(
                color: Colors.black54, // Semi-transparent background
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _animation.value),
                        child: child,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.touch_app_rounded,
                          color: Colors.white,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Swipe up for next video',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Icon(
                          Icons.keyboard_double_arrow_up_rounded,
                          color: Colors.white70,
                          size: 48,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
