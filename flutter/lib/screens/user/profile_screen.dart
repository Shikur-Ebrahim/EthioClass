import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../auth/login_screen.dart';
import 'personal_info_screen.dart';
import 'change_password_screen.dart';
import 'security_screen.dart';

class ProfileScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Row(
              children: [
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
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName.isNotEmpty ? userName : 'Student',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMedium,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {},
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded,
                                size: 16, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Account Section
            const _SectionTitle(title: 'Account'),
            const SizedBox(height: 12),
            _SettingsCard(
              children: [
                _SettingsItem(
                  icon: Icons.person_rounded,
                  title: 'Personal Information',
                  subtitle: 'Update your personal details',
                  iconBgColor: Colors.blue.withOpacity(0.1),
                  iconColor: Colors.blue,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonalInfoScreen(
                          currentName: userName,
                          currentEmail: userEmail,
                          currentPhone: userPhone,
                          accessToken: accessToken,
                        ),
                      ),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Icons.lock_rounded,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  iconBgColor: Colors.blue.withOpacity(0.1),
                  iconColor: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangePasswordScreen(accessToken: accessToken),
                      ),
                    );
                  },
                ),
                _SettingsItem(
                  icon: Icons.security_rounded,
                  title: 'Security',
                  subtitle: 'Manage account security',
                  iconBgColor: Colors.blue.withOpacity(0.1),
                  iconColor: Colors.blue,
                  showBorder: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SecurityScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Preferences Section
            const _SectionTitle(title: 'Preferences'),
            const SizedBox(height: 12),
            _SettingsCard(
              children: [
                _SettingsItem(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'Choose your preferred language',
                  iconBgColor: Colors.indigo.withOpacity(0.1),
                  iconColor: Colors.indigo,
                  trailing: const Text(
                    'English',
                    style: TextStyle(fontSize: 13, color: AppColors.textMedium),
                  ),
                ),
                _SettingsItem(
                  icon: Icons.hd_rounded,
                  title: 'Video Quality',
                  subtitle: 'Select default video quality',
                  iconBgColor: Colors.purple.withOpacity(0.1),
                  iconColor: Colors.purple,
                  trailing: const Text(
                    'Auto',
                    style: TextStyle(fontSize: 13, color: AppColors.textMedium),
                  ),
                ),
                _SettingsItem(
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  subtitle: 'Manage your notification preferences',
                  iconBgColor: Colors.green.withOpacity(0.1),
                  iconColor: Colors.green,
                ),
                _SettingsItem(
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme',
                  iconBgColor: Colors.orange.withOpacity(0.1),
                  iconColor: Colors.orange,
                  showBorder: false,
                  trailing: Switch(
                    value: false, // Hardcoded to false for light theme
                    onChanged: (val) {},
                    activeColor: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Other Section
            const _SectionTitle(title: 'Other'),
            const SizedBox(height: 12),
            _SettingsCard(
              children: [
                _SettingsItem(
                  icon: Icons.cleaning_services_rounded,
                  title: 'Clear Cache',
                  subtitle: 'Free up storage space',
                  iconBgColor: Colors.blueGrey.withOpacity(0.1),
                  iconColor: Colors.blueGrey,
                  trailing: const Text(
                    '45.6 MB',
                    style: TextStyle(fontSize: 13, color: AppColors.textMedium),
                  ),
                ),
                _SettingsItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  subtitle: 'Sign out from your account',
                  iconBgColor: AppColors.error.withOpacity(0.1),
                  iconColor: AppColors.error,
                  showBorder: false,
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBgColor;
  final Color iconColor;
  final bool showBorder;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBgColor,
    required this.iconColor,
    this.showBorder = true,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: showBorder
              ? const Border(
                  bottom: BorderSide(color: AppColors.greyLight, width: 1))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
