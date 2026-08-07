import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../auth/presentation/providers/user_profile_provider.dart';
import 'course_details_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _darkMode = true;
  String _language = 'English';
  String _videoQuality = 'Auto';

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: CourseColors.bg,
      appBar: AppBar(
        backgroundColor: CourseColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: CourseColors.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Settings',
            style: TextStyle(color: CourseColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // ── Profile Header ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: profileAsync.when(
              data: (profile) => Row(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: CourseColors.yellow,
                    shape: BoxShape.circle,
                    border: Border.all(color: CourseColors.yellow, width: 2),
                  ),
                  child: const Icon(Icons.person, size: 34, color: Colors.black),
                ),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(profile?.fullName ?? 'Student',
                      style: const TextStyle(color: CourseColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(profile?.fullName.isNotEmpty == true ? 'student@email.com' : 'student@email.com',
                      style: const TextStyle(color: CourseColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {},
                    child: const Text('Edit Profile >',
                        style: TextStyle(color: CourseColors.yellow, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ]),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ),
          const Divider(color: CourseColors.border, height: 1),

          // ── Account Section ──────────────────────────────────
          _SectionHeader(title: 'Account'),
          _SettingsTile(
            icon: Icons.person_outline,
            iconColor: CourseColors.primaryBlue,
            title: 'Personal Information',
            subtitle: 'Update your personal details',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            iconColor: const Color(0xFF7C3AED),
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.security_outlined,
            iconColor: CourseColors.success,
            title: 'Security',
            subtitle: 'Manage account security',
            onTap: () {},
          ),
          const Divider(color: CourseColors.border, height: 1, indent: 20, endIndent: 20),

          // ── Preferences Section ──────────────────────────────
          _SectionHeader(title: 'Preferences'),
          _SettingsTile(
            icon: Icons.language_outlined,
            iconColor: CourseColors.primaryBlue,
            title: 'Language',
            subtitle: 'Choose your preferred language',
            trailing: Text(_language,
                style: const TextStyle(color: CourseColors.textSecondary, fontSize: 13)),
            onTap: () => _showLanguagePicker(),
          ),
          _SettingsTile(
            icon: Icons.hd_outlined,
            iconColor: Colors.red.shade400,
            title: 'Video Quality',
            subtitle: 'Select default video quality',
            trailing: Text(_videoQuality,
                style: const TextStyle(color: CourseColors.textSecondary, fontSize: 13)),
            onTap: () => _showQualityPicker(),
          ),
          _SettingsTile(
            icon: Icons.notifications_none,
            iconColor: CourseColors.yellow,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            onTap: () {},
          ),
          // Dark Mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: CourseColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CourseColors.border),
              ),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4C1D95).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.dark_mode_outlined, color: Color(0xFF8B5CF6), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Dark Mode', style: TextStyle(color: CourseColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                  SizedBox(height: 3),
                  Text('Use dark theme', style: TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
                ])),
                Switch(
                  value: _darkMode,
                  onChanged: (v) => setState(() => _darkMode = v),
                  activeColor: Colors.white,
                  activeTrackColor: CourseColors.primaryBlue,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: CourseColors.border,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: CourseColors.border, height: 1, indent: 20, endIndent: 20),

          // ── Other Section ────────────────────────────────────
          _SectionHeader(title: 'Other'),
          _SettingsTile(
            icon: Icons.cleaning_services_outlined,
            iconColor: CourseColors.primaryBlue,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            trailing: const Text('45.6 MB',
                style: TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
            onTap: () => _showClearCacheDialog(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: GestureDetector(
              onTap: () async {
                await ref.read(authProvider.notifier).signOut();
                if (mounted) context.go('/login');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.logout, color: Colors.red.shade400, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Logout', style: TextStyle(color: Colors.red.shade400, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    const Text('Sign out from your account',
                        style: TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
                  ])),
                  Icon(Icons.chevron_right, color: Colors.red.shade400, size: 20),
                ]),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CourseColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PickerSheet(
        title: 'Select Language',
        options: ['English', 'Amharic', 'Oromiffa', 'Tigrinya'],
        selected: _language,
        onSelect: (v) { setState(() => _language = v); Navigator.pop(context); },
      ),
    );
  }

  void _showQualityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CourseColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PickerSheet(
        title: 'Video Quality',
        options: ['Auto', '1080p', '720p', '480p', '360p'],
        selected: _videoQuality,
        onSelect: (v) { setState(() => _videoQuality = v); Navigator.pop(context); },
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CourseColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cache', style: TextStyle(color: CourseColors.textPrimary, fontWeight: FontWeight.bold)),
        content: const Text('This will free up 45.6 MB of storage. Are you sure?',
            style: TextStyle(color: CourseColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: CourseColors.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: CourseColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
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
      currentIndex: 4,
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

// ─────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(title,
          style: const TextStyle(color: CourseColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.iconColor, required this.title,
      required this.subtitle, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CourseColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CourseColors.border),
          ),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
            ])),
            if (trailing != null) ...[trailing!, const SizedBox(width: 4)],
            const Icon(Icons.chevron_right, color: CourseColors.textSecondary, size: 18),
          ]),
        ),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final String title, selected;
  final List<String> options;
  final ValueChanged<String> onSelect;
  const _PickerSheet({required this.title, required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 12),
      Container(width: 40, height: 4, decoration: BoxDecoration(color: CourseColors.border, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      ...options.map((opt) => ListTile(
        title: Text(opt, style: const TextStyle(color: CourseColors.textPrimary)),
        trailing: opt == selected ? const Icon(Icons.check, color: CourseColors.yellow) : null,
        onTap: () => onSelect(opt),
      )),
      const SizedBox(height: 16),
    ]);
  }
}
