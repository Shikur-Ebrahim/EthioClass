import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../auth/presentation/providers/user_profile_provider.dart';
import '../screens/course_details_screen.dart';
import '../screens/my_learning_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/messages_screen.dart';

class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Drawer(
      backgroundColor: CourseColors.bg,
      child: Column(
        children: [
          // ── Logo + close header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: CourseColors.yellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school, color: Colors.black, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: 'Ethio', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              TextSpan(text: 'Class', style: TextStyle(color: CourseColors.yellow, fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Text('Learn Today, Lead Tomorrow',
                            style: TextStyle(color: CourseColors.textSecondary, fontSize: 10)),
                      ],
                    ),
                  ]),
                  IconButton(
                    icon: const Icon(Icons.close, color: CourseColors.textSecondary, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: CourseColors.border, height: 1),
          const SizedBox(height: 12),
          // ── Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _SidebarItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', isActive: true, onTap: () { Navigator.of(context).pop(); }),
                _SidebarItem(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: 'Courses', onTap: () { Navigator.of(context).pop(); }),
                _SidebarItem(
                  icon: Icons.school_outlined, activeIcon: Icons.school, label: 'My Learning',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyLearningScreen()));
                  },
                ),
                _SidebarItem(icon: Icons.download_for_offline_outlined, activeIcon: Icons.download_for_offline, label: 'Downloads', onTap: () { Navigator.of(context).pop(); }),
                _SidebarItem(icon: Icons.bookmark_border, activeIcon: Icons.bookmark, label: 'Bookmarks', onTap: () { Navigator.of(context).pop(); }),
                _SidebarItem(icon: Icons.note_alt_outlined, activeIcon: Icons.note_alt, label: 'My Notes', onTap: () { Navigator.of(context).pop(); }),
                _SidebarItem(
                  icon: Icons.notifications_none, activeIcon: Icons.notifications, label: 'Notifications', badge: 3,
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  },
                ),
                _SidebarItem(
                  icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Messages',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MessagesScreen()));
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Divider(color: CourseColors.border),
                ),
                _SidebarItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings', onTap: () { Navigator.of(context).pop(); }),
                _SidebarItem(icon: Icons.help_outline, activeIcon: Icons.help, label: 'Help & Support', onTap: () { Navigator.of(context).pop(); }),
                _SidebarItem(icon: Icons.info_outline, activeIcon: Icons.info, label: 'About EthioClass', onTap: () { Navigator.of(context).pop(); }),
                const SizedBox(height: 8),
                // ── Log Out
                _SidebarItem(
                  icon: Icons.logout,
                  activeIcon: Icons.logout,
                  label: 'Log Out',
                  isDestructive: true,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
          ),
          // ── User profile footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: profileAsync.when(
              data: (profile) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CourseColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CourseColors.border),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: CourseColors.yellow,
                    child: Text(
                      profile?.fullName.isNotEmpty == true ? profile!.fullName[0].toUpperCase() : 'S',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(profile?.fullName ?? 'Student',
                        style: const TextStyle(color: CourseColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(profile?.role == 'admin' ? 'Admin' : 'Grade 12 Student',
                        style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
                  ])),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: CourseColors.textSecondary, size: 20),
                    onPressed: () { Navigator.of(context).pop(); },
                  ),
                ]),
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SIDEBAR ITEM WIDGET
// ─────────────────────────────────────────────────────────────
class _SidebarItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool isActive, isDestructive;
  final int badge;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.isDestructive = false,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Colors.red.shade400
        : isActive
            ? Colors.white
            : CourseColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isActive ? CourseColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(isActive ? activeIcon : icon, color: color, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: TextStyle(color: color, fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
          ),
          if (badge > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: CourseColors.primaryBlue, borderRadius: BorderRadius.circular(12)),
              child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ]),
      ),
    );
  }
}
