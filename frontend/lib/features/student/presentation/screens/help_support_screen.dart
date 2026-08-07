import 'package:flutter/material.dart';
import 'course_details_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
        title: const Text('Help & Support',
            style: TextStyle(color: CourseColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Hero Banner ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E50FF), Color(0xFF0F2B5B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('How can we help you?',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.3)),
                  SizedBox(height: 8),
                  Text('We\'re here to support your\nlearning journey.',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
                ]),
              ),
              Stack(alignment: Alignment.center, children: [
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
                const Icon(Icons.school, size: 44, color: CourseColors.yellow),
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    width: 22, height: 22,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.question_mark, size: 14, color: CourseColors.primaryBlue),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(color: CourseColors.yellow, shape: BoxShape.circle),
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 28),

          // ── Popular Help Topics ───────────────────────────────
          const Text('Popular Help Topics',
              style: TextStyle(color: CourseColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: CourseColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CourseColors.border),
            ),
            child: Column(children: [
              _HelpTopicTile(icon: Icons.rocket_launch_outlined, iconColor: CourseColors.primaryBlue, title: 'Getting Started', subtitle: 'Learn how to use EthioClass', isFirst: true),
              _HelpTopicTile(icon: Icons.menu_book_outlined, iconColor: CourseColors.success, title: 'How to Enroll in a Course', subtitle: 'Step-by-step guide'),
              _HelpTopicTile(icon: Icons.payment_outlined, iconColor: CourseColors.yellow, title: 'Payments & Subscriptions', subtitle: 'Learn about payments and unlocks'),
              _HelpTopicTile(icon: Icons.card_membership_outlined, iconColor: const Color(0xFF8B5CF6), title: 'Certificates', subtitle: 'How to earn and download certificates'),
              _HelpTopicTile(icon: Icons.bug_report_outlined, iconColor: Colors.red.shade400, title: 'Technical Issues', subtitle: 'Fix playback and app issues', isLast: true),
            ]),
          ),
          const SizedBox(height: 28),

          // ── Still Need Help ───────────────────────────────────
          const Text('Still Need Help?',
              style: TextStyle(color: CourseColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          // Live Chat + Email Support row
          Row(children: [
            Expanded(
              child: _ContactCard(
                icon: Icons.headset_mic_outlined,
                iconColor: CourseColors.primaryBlue,
                title: 'Live Chat',
                subtitle: 'Chat with our support team',
                badge: 'Online',
                badgeColor: CourseColors.success,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ContactCard(
                icon: Icons.email_outlined,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Email Support',
                subtitle: 'We reply within 24h',
                badge: 'support@ethioclass.com',
                badgeColor: CourseColors.textSecondary,
                onTap: () {},
              ),
            ),
          ]),
          const SizedBox(height: 12),
          // Call Us
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CourseColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CourseColors.border),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: CourseColors.success.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_outlined, color: CourseColors.success, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Call Us', style: TextStyle(color: CourseColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('+251 911 234 567',
                      style: TextStyle(color: CourseColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                ])),
                const Text('Mon – Fri: 8:00 AM – 6:00 PM',
                    style: TextStyle(color: CourseColors.textSecondary, fontSize: 10)),
              ]),
            ),
          ),
          const SizedBox(height: 24),
        ],
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

class _HelpTopicTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final bool isFirst, isLast;
  const _HelpTopicTile({required this.icon, required this.iconColor, required this.title,
      required this.subtitle, this.isFirst = false, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
            ])),
            const Icon(Icons.chevron_right, color: CourseColors.textSecondary, size: 20),
          ]),
        ),
      ),
      if (!isLast) const Divider(color: CourseColors.border, height: 1, indent: 68),
    ]);
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle, badge;
  final Color badgeColor;
  final VoidCallback onTap;
  const _ContactCard({required this.icon, required this.iconColor, required this.title,
      required this.subtitle, required this.badge, required this.badgeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CourseColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CourseColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(children: [
            if (badge == 'Online') Container(
              width: 7, height: 7,
              margin: const EdgeInsets.only(right: 5),
              decoration: const BoxDecoration(color: CourseColors.success, shape: BoxShape.circle),
            ),
            Flexible(child: Text(badge,
                style: TextStyle(color: badgeColor, fontSize: 10),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
        ]),
      ),
    );
  }
}
