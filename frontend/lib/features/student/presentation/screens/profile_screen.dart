import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/user_profile_provider.dart';
import 'course_details_screen.dart'; // Reuse CourseColors

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: CourseColors.bg,
      appBar: AppBar(
        backgroundColor: CourseColors.bg,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Profile', style: TextStyle(color: CourseColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Manage your learning journey', style: TextStyle(color: CourseColors.textSecondary, fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: CourseColors.border)),
              child: const Icon(Icons.settings_outlined, color: CourseColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            profileAsync.when(
              data: (profile) => _buildAvatarSection(profile?.fullName ?? 'Student', profile?.role ?? 'student'),
              loading: () => const CircularProgressIndicator(color: CourseColors.yellow),
              error: (_, __) => _buildAvatarSection('Student', 'student'),
            ),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildPremiumBanner(),
            const SizedBox(height: 24),
            _buildMenuSection(context, ref),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAvatarSection(String name, String role) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: CourseColors.yellow, width: 3),
              ),
              child: ClipOval(
                child: Container(
                  color: const Color(0xFFFBBF24),
                  child: const Icon(Icons.person, size: 50, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: CourseColors.primaryBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: CourseColors.bg, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(name, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            const Icon(Icons.verified, color: CourseColors.primaryBlue, size: 18),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: CourseColors.primaryBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: CourseColors.primaryBlue.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school, color: CourseColors.primaryBlue, size: 12),
              const SizedBox(width: 4),
              Text(role == 'admin' ? 'Admin' : 'Grade 12 Student', style: const TextStyle(color: CourseColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildContactRow(Icons.email_outlined, 'abelbekele12@gmail.com'),
        const SizedBox(height: 8),
        _buildContactRow(Icons.phone_outlined, '+251 912 345 678'),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: CourseColors.textSecondary, size: 14),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CourseColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CourseColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: '12', label: 'Courses\nEnrolled', icon: Icons.menu_book, color: CourseColors.primaryBlue),
          _VertDivider(),
          _StatItem(value: '48', label: 'Lessons\nWatched', icon: Icons.play_circle, color: CourseColors.success),
          _VertDivider(),
          _StatItem(value: '36h 45m', label: 'Time\nLearned', icon: Icons.access_time, color: const Color(0xFF8B5CF6)),
          _VertDivider(),
          _StatItem(value: '4.8', label: 'Avg.\nRating', icon: Icons.star, color: CourseColors.yellow),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2B5B), Color(0xFF1A3A70)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E50FF).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CourseColors.yellow.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, color: CourseColors.yellow, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Go Premium', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Unlock all courses, downloads\nand premium features.', style: TextStyle(color: CourseColors.textSecondary, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: CourseColors.yellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Row(
              children: const [
                Text('Upgrade Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: CourseColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CourseColors.border),
      ),
      child: Column(
        children: [
          _MenuTile(icon: Icons.card_membership_outlined, label: 'My Certificates', onTap: () {}),
          _Divider(),
          _MenuTile(icon: Icons.credit_card_outlined, label: 'Payment History', onTap: () {}),
          _Divider(),
          _MenuTile(icon: Icons.headset_mic_outlined, label: 'Help & Support', onTap: () {}),
          _Divider(),
          _MenuTile(icon: Icons.settings_outlined, label: 'Settings', onTap: () {}),
          _Divider(),
          _MenuTile(icon: Icons.info_outline, label: 'About EthioClass', onTap: () {}),
          _Divider(),
          _MenuTile(
            icon: Icons.logout_outlined,
            label: 'Logout',
            isDestructive: true,
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: CourseColors.bg,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: CourseColors.yellow,
      unselectedItemColor: CourseColors.textSecondary,
      currentIndex: 4, // Profile active
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Courses'),
        BottomNavigationBarItem(icon: Icon(Icons.download_for_offline_outlined), label: 'Downloads'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: 'Bookmarks'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}

// -------------------------
// Helper Widgets
// -------------------------
class _StatItem extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;

  const _StatItem({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 10, height: 1.4), textAlign: TextAlign.center),
      ],
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 50, color: CourseColors.border);
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: CourseColors.border, indent: 20, endIndent: 20);
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuTile({required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade400 : CourseColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive ? Colors.red.withOpacity(0.1) : CourseColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isDestructive ? Colors.red.shade400 : CourseColors.primaryBlue, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500))),
            Icon(Icons.chevron_right, color: CourseColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
