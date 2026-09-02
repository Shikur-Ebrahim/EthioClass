import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import 'personal_info_screen.dart';
import 'settings_screen.dart';
import '../../models/guidance_video.dart';
import '../../services/guidance_service.dart';
import '../../config/api_config.dart';
import 'guidance_feed_screen.dart';
import '../auth/signup_screen.dart';
import '../auth/login_screen.dart';
import '../../services/session_service.dart';
import '../../widgets/ethioclass_loading.dart';

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
  bool _hasRegisteredDevice = false;
  List<GuidanceVideo> _videos = [];

  @override
  void initState() {
    super.initState();
    _checkRegistration();
    _loadVideos();
  }

  Future<void> _checkRegistration() async {
    final hasReg = await SessionService.hasDeviceRegistered();
    if (mounted) {
      setState(() {
        _hasRegisteredDevice = hasReg;
      });
    }
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
                      widget.userName.isNotEmpty
                          ? widget.userName[0].toUpperCase()
                          : 'S',
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
                        widget.userName.isNotEmpty
                            ? widget.userName
                            : 'Student',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.userEmail.isNotEmpty &&
                          !(widget.userEmail.endsWith('@ethioclass.com') &&
                              widget.userEmail
                                      .replaceAll('@ethioclass.com', '')
                                      .length ==
                                  10))
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
                          if (widget.userName.isEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _hasRegisteredDevice
                                    ? const LoginScreen()
                                    : const SignupScreen(),
                              ),
                            );
                            return;
                          }
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
                          children: [
                            Text(
                              widget.userName.isEmpty
                                  ? (_hasRegisteredDevice
                                        ? 'Log In'
                                        : 'Create Account')
                                  : 'Edit Profile',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFFB800),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: Color(0xFFFFB800),
                            ),
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

          // Guidance Videos Grid Section
          Expanded(
            child: _isLoading
                ? const Center(child: EthioClassLoading())
                : _videos.isEmpty
                ? const Center(
                    child: Text(
                      'No guidance videos yet.',
                      style: TextStyle(color: AppColors.textMedium),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio:
                              0.7, // Taller items for video thumbnails
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
                                    ? CachedNetworkImage(
                                        imageUrl: thumbUrl,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) =>
                                            const Center(
                                              child: Icon(
                                                Icons.video_library,
                                                color: Colors.grey,
                                                size: 40,
                                              ),
                                            ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.video_library,
                                          color: Colors.grey,
                                          size: 40,
                                        ),
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
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white70,
                                  size: 48,
                                ),
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
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
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
          ),
        ],
      ),
    );
  }
}
