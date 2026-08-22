import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';

class CustomDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final void Function(int index)? onNavigate;
  final int selectedIndex;

  const CustomDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    this.onNavigate,
    this.selectedIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface, // Light theme as requested
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EthioClass',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Learn Today, Lead Tomorrow',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.greyLight, height: 1),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    isSelected: selectedIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate?.call(0);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.menu_book_outlined,
                    label: 'Courses',
                    isSelected: selectedIndex == 1,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate?.call(1);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.school_outlined,
                    label: 'My Learning',
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.grey, size: 20),
                    onTap: () {},
                  ),
                  _DrawerItem(
                    icon: Icons.play_circle_outline_rounded,
                    label: 'How to start',
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.grey, size: 20),
                    onTap: () {},
                  ),
                  _DrawerItem(
                    icon: Icons.download_outlined,
                    label: 'Downloads',
                    isSelected: selectedIndex == 2,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate?.call(2);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.bookmark_border_rounded,
                    label: 'Bookmarks',
                    isSelected: selectedIndex == 3,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate?.call(3);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.article_outlined,
                    label: 'My Notes',
                    onTap: () {},
                  ),
                  _DrawerItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    trailing: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {},
                  ),
                  _DrawerItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Messages',
                    onTap: () {},
                  ),
                  _DrawerItem(
                    icon: Icons.person_add_outlined,
                    label: 'Create Account',
                    onTap: () {
                      Navigator.pop(context); // close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Divider(color: AppColors.greyLight, height: 1),
                  ),
                  
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {},
                  ),
                  _DrawerItem(
                    icon: Icons.headset_mic_outlined,
                    label: 'Help & Support',
                    onTap: () {},
                  ),
                  _DrawerItem(
                    icon: Icons.info_outline_rounded,
                    label: 'About EthioClass',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            
            // Logout
            Padding(
              padding: const EdgeInsets.all(20),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, color: AppColors.error),
                      const SizedBox(width: 14),
                      const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;
  final Widget? trailing;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textMedium,
        size: 24,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textDark,
        ),
      ),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
    );
  }
}
