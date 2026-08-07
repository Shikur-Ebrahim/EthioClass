import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/user_profile_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.yellow)),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
          data: (profile) => CustomScrollView(
            slivers: [
              // Top App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Panel 🛠️',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Welcome, ${profile?.fullName ?? 'Admin'}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 21,
                        backgroundColor: AppColors.yellow,
                        child: Text(
                          (profile?.fullName.isNotEmpty == true)
                              ? profile!.fullName[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Stats Row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(
                    children: [
                      _StatCard(label: 'Students', value: '0', icon: Icons.people_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Courses', value: '0', icon: Icons.book_outlined, color: AppColors.yellow),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Revenue', value: '\$0', icon: Icons.payments_outlined, color: Colors.green),
                    ],
                  ),
                ),
              ),

              // Admin Menu Items
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Management',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _AdminMenuItem(icon: Icons.book_outlined, label: 'Course Management', subtitle: 'Create and manage courses', onTap: () {}),
                      const SizedBox(height: 10),
                      _AdminMenuItem(icon: Icons.video_library_outlined, label: 'Lesson & Video Management', subtitle: 'Upload videos to Cloudflare R2', onTap: () {}),
                      const SizedBox(height: 10),
                      _AdminMenuItem(icon: Icons.people_outline, label: 'Student Management', subtitle: 'View and manage all students', onTap: () {}),
                      const SizedBox(height: 10),
                      _AdminMenuItem(icon: Icons.person_outline, label: 'Instructor Management', subtitle: 'Add and remove instructors', onTap: () {}),
                      const SizedBox(height: 10),
                      _AdminMenuItem(icon: Icons.receipt_long_outlined, label: 'Enrollment Management', subtitle: 'Approve or reject enrollments', onTap: () {}),
                      const SizedBox(height: 10),
                      _AdminMenuItem(icon: Icons.bar_chart_outlined, label: 'Revenue Reports', subtitle: 'Payment history and analytics', onTap: () {}),
                      const SizedBox(height: 24),
                      // Logout
                      TextButton.icon(
                        onPressed: () async {
                          await ref.read(authProvider.notifier).signOut();
                          if (context.mounted) context.go('/onboarding');
                        },
                        icon: const Icon(Icons.logout, color: AppColors.error, size: 18),
                        label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminMenuItem({required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.yellow.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.yellow, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 14),
          ],
        ),
      ),
    );
  }
}
