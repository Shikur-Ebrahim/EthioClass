import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/session_service.dart';
import '../auth/login_screen.dart';
import 'personal_info_screen.dart';
import 'settings_screen.dart';
import '../../models/guidance_video.dart';
import '../../services/guidance_service.dart';
import '../../widgets/guidance_video_player.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userPhone;
  final String accessToken;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userPhone = '',
    this.accessToken = '',
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  List<GuidanceVideo> _videos = [];
  int _currentVideoIndex = 0;

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
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header (Fixed at top)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Name + email + edit profile
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName.isNotEmpty ? widget.userName : 'Student',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.userEmail,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMedium,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PersonalInfoScreen(
                                currentName: widget.userName,
                                currentEmail: widget.userEmail,
                                currentPhone: widget.userPhone,
                                accessToken: widget.accessToken,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFFB800),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded,
                                size: 16, color: Color(0xFFFFB800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Blue settings icon circle
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Guidance Videos Swiper Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _videos.isEmpty
                    ? const Center(
                        child: Text(
                          'No guidance videos yet.',
                          style: TextStyle(color: AppColors.textMedium),
                        ),
                      )
                    : PageView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: _videos.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentVideoIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final video = _videos[index];
                          return ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                            child: GuidanceVideoPlayer(
                              video: video,
                              isPlaying: index == _currentVideoIndex,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
