import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import '../../core/theme.dart';
import '../../widgets/custom_drawer.dart';
import '../../services/mini_player_service.dart';
import 'home_screen.dart';
import 'courses_screen.dart';
import 'downloads_screen.dart';
import 'bookmarks_screen.dart';
import 'profile_screen.dart';
import '../../services/session_service.dart';
import 'lesson_detail_screen.dart';

/// MainLayout wraps the bottom nav and manages tab switching.
class MainLayout extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userPhone;
  final String accessToken;

  const MainLayout({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userPhone = '',
    this.accessToken = '',
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  bool _hasRegisteredDevice = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _checkDeviceRegistration();
    _pages = [
      HomeScreen(
        userName: widget.userName,
        onGoToCourses: () => setState(() => _selectedIndex = 1),
      ),
      const CoursesScreen(),
      const DownloadsScreen(),
      const BookmarksScreen(),
      ProfileScreen(userName: widget.userName, userEmail: widget.userEmail, userPhone: widget.userPhone, accessToken: widget.accessToken),
    ];
  }

  Future<void> _checkDeviceRegistration() async {
    final hasReg = await SessionService.hasDeviceRegistered();
    if (mounted) {
      setState(() {
        _hasRegisteredDevice = hasReg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MiniPlayerService.instance,
      builder: (context, _) {
        final mini = MiniPlayerService.instance;
        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: CustomDrawer(
            userName: widget.userName,
            userEmail: widget.userEmail,
            selectedIndex: _selectedIndex,
            hasRegisteredDevice: _hasRegisteredDevice,
            onNavigate: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          body: Stack(
            children: [
              IndexedStack(
                index: _selectedIndex,
                children: _pages,
              ),
              // ── Mini Player ────────────────────────────────────────────────
              if (mini.isActive && mini.isMinimized)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 70,
                  child: GestureDetector(
                    onTap: () {
                      final lesson = mini.lesson!;
                      mini.expand();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LessonDetailScreen(
                            courseTitle: mini.courseTitle ?? '',
                            chapterTitle: lesson.title,
                            lessons: [lesson],
                            initialLessonIndex: 0,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Video thumbnail
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(14),
                              bottomLeft: Radius.circular(14),
                            ),
                            child: SizedBox(
                              width: 100,
                              height: 72,
                              child: mini.chewieController != null
                                  ? Chewie(controller: mini.chewieController!)
                                  : const ColoredBox(color: Colors.black),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mini.lesson!.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  mini.courseTitle ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          // Play/Pause toggle
                          IconButton(
                            icon: Icon(
                              mini.videoController?.value.isPlaying == true ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              if (mini.videoController?.value.isPlaying == true) {
                                mini.videoController?.pause();
                              } else {
                                mini.videoController?.play();
                              }
                              setState(() {});
                            },
                          ),
                          // Close button
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
                            onPressed: () => mini.close(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      selected: _selectedIndex == 0,
                      onTap: () => setState(() => _selectedIndex = 0),
                    ),
                    _NavItem(
                      icon: Icons.menu_book_rounded,
                      label: 'Courses',
                      selected: _selectedIndex == 1,
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),
                    _NavItem(
                      icon: Icons.download_rounded,
                      label: 'Downloads',
                      selected: _selectedIndex == 2,
                      onTap: () => setState(() => _selectedIndex = 2),
                    ),
                    _NavItem(
                      icon: Icons.bookmark_border_rounded,
                      label: 'Bookmarks',
                      selected: _selectedIndex == 3,
                      onTap: () => setState(() => _selectedIndex = 3),
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      selected: _selectedIndex == 4,
                      onTap: () => setState(() => _selectedIndex = 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.primary : AppColors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? AppColors.primary : AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

