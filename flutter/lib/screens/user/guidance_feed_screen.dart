import 'package:flutter/material.dart';
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

class _GuidanceFeedScreenState extends State<GuidanceFeedScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
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
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.videos.length,
        onPageChanged: (index) {
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
    );
  }
}
