import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/guidance_video.dart';
import '../../services/guidance_service.dart';
import '../../config/api_config.dart';
import 'guidance_feed_screen.dart';
import '../../widgets/ethioclass_loading.dart';

class HowToStartScreen extends StatefulWidget {
  const HowToStartScreen({super.key});

  @override
  State<HowToStartScreen> createState() => _HowToStartScreenState();
}

class _HowToStartScreenState extends State<HowToStartScreen> {
  bool _isLoading = true;
  List<GuidanceVideo> _videos = [];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      final videos = await GuidanceService.instance.getVideos();
      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: const Text(
          'How to Start',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: EthioClassLoading())
          : _videos.isEmpty
              ? const Center(
                  child: Text(
                    'No guidance videos available yet.',
                    style: TextStyle(color: AppColors.textMedium),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    final thumbUrl = video.thumbnailUrl.startsWith('http') 
                      ? video.thumbnailUrl 
                      : '$apiBaseUrl/media/${video.thumbnailUrl}';
                      
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GuidanceFeedScreen(
                              videos: _videos,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Thumbnail Image
                            Container(
                              color: Colors.grey[300],
                              child: video.thumbnailUrl.isNotEmpty
                                ? Image.network(
                                    thumbUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.video_library, color: Colors.grey, size: 40),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(Icons.video_library, color: Colors.grey, size: 40),
                                  ),
                            ),
                            // Dark Gradient Overlay
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black87,
                                  ],
                                  stops: [0.6, 1.0],
                                ),
                              ),
                            ),
                            // Play icon at center
                            const Center(
                              child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 48),
                            ),
                            // Title and Number at bottom
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    radius: 10,
                                    child: Text(
                                      '${video.orderIndex}',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      video.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
