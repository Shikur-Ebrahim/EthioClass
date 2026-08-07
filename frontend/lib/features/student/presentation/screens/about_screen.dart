import 'package:flutter/material.dart';
import 'course_details_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourseColors.bg,
      appBar: AppBar(
        backgroundColor: CourseColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: CourseColors.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('About EthioClass',
            style: TextStyle(color: CourseColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Logo ─────────────────────────────────────────────
            const SizedBox(height: 16),
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                color: CourseColors.yellow,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: CourseColors.yellow.withOpacity(0.3), blurRadius: 20, spreadRadius: 4)],
              ),
              child: const Icon(Icons.school, color: Colors.black, size: 50),
            ),
            const SizedBox(height: 20),
            // Brand name
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(text: 'Ethio', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                  TextSpan(text: 'Class', style: TextStyle(color: CourseColors.yellow, fontSize: 30, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text('Learn Today, Lead Tomorrow',
                style: TextStyle(color: CourseColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: CourseColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Version 1.0.0',
                  style: TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
            ),
            const SizedBox(height: 24),
            // ── Description ───────────────────────────────────────
            const Text(
              'EthioClass is Ethiopia\'s leading online learning platform designed to provide high-quality video lessons for students at different academic levels. Our mission is to make quality education accessible to every student, anytime, anywhere.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CourseColors.textSecondary, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 28),
            // ── Feature Cards ─────────────────────────────────────
            _FeatureCard(
              icon: Icons.menu_book_outlined,
              iconColor: CourseColors.primaryBlue,
              bgColor: CourseColors.primaryBlue,
              title: 'Quality Education',
              subtitle: 'Well-structured video lessons from expert instructors.',
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              icon: Icons.people_outline,
              iconColor: CourseColors.success,
              bgColor: CourseColors.success,
              title: 'Learn Anytime, Anywhere',
              subtitle: 'Access your courses on any device, anytime.',
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              icon: Icons.emoji_events_outlined,
              iconColor: CourseColors.yellow,
              bgColor: CourseColors.yellow,
              title: 'Empowering Students',
              subtitle: 'Helping students achieve their academic goals.',
            ),
            const SizedBox(height: 28),
            // ── Legal links ───────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: CourseColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CourseColors.border),
              ),
              child: Column(children: [
                _LegalTile(icon: Icons.description_outlined, label: 'Terms of Service', onTap: () {}),
                const Divider(color: CourseColors.border, height: 1, indent: 56),
                _LegalTile(icon: Icons.shield_outlined, label: 'Privacy Policy', onTap: () {}),
                const Divider(color: CourseColors.border, height: 1, indent: 56),
                _LegalTile(icon: Icons.article_outlined, label: 'Licenses', onTap: () {}),
              ]),
            ),
            const SizedBox(height: 32),
            // ── Footer ────────────────────────────────────────────
            Text('© 2025 EthioClass. All rights reserved.',
                style: TextStyle(color: CourseColors.textSecondary.withOpacity(0.6), fontSize: 12)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Made with ', style: TextStyle(color: CourseColors.textSecondary.withOpacity(0.6), fontSize: 12)),
              const Icon(Icons.favorite, color: Colors.red, size: 13),
              Text(' in Ethiopia', style: TextStyle(color: CourseColors.textSecondary.withOpacity(0.6), fontSize: 12)),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
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

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, bgColor;
  final String title, subtitle;
  const _FeatureCard({required this.icon, required this.iconColor, required this.bgColor,
      required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CourseColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CourseColors.border),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 12, height: 1.4)),
        ])),
      ]),
    );
  }
}

class _LegalTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LegalTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(children: [
          Icon(icon, color: CourseColors.textSecondary, size: 22),
          const SizedBox(width: 16),
          Expanded(child: Text(label,
              style: const TextStyle(color: CourseColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
          const Icon(Icons.chevron_right, color: CourseColors.textSecondary, size: 20),
        ]),
      ),
    );
  }
}
