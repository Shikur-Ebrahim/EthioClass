import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/session_service.dart';
import '../auth/login_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  final String userName;
  final String userEmail;

  const AdminHomeScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  Future<void> _logout(BuildContext context) async {
    await SessionService.clearSession();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome, Admin!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userName.isNotEmpty ? userName : 'Administrator',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userEmail,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'This is the admin control panel. Future administrative features will be added here.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
