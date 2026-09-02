import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: AppColors.textDark),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF064E3B),
                          Color(0xFF16A34A),
                          Color(0xFF4ADE80),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Color(0xFF16A34A),
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'EthioClass',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Learn Today, Lead Tomorrow',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Version badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF16A34A).withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF16A34A),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Version 1.0.0  •  Made in Ethiopia 🇪🇹',
                            style: TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mission Card
                  _InfoCard(
                    icon: Icons.flag_rounded,
                    iconColor: const Color(0xFF16A34A),
                    iconBg: const Color(0xFFDCFCE7),
                    title: 'Our Mission',
                    content:
                        'EthioClass is built to empower Ethiopian students with world-class digital education. '
                        'We believe every student — regardless of location — deserves access to high-quality '
                        'lessons, notes, and exam preparation materials right from their phone.',
                  ),
                  const SizedBox(height: 14),

                  // What We Offer
                  _InfoCard(
                    icon: Icons.auto_awesome_rounded,
                    iconColor: Colors.amber.shade700,
                    iconBg: const Color(0xFFFEF9C3),
                    title: 'What We Offer',
                    customContent: const Column(
                      children: [
                        _FeatureRow(
                          icon: Icons.play_circle_rounded,
                          color: Color(0xFF16A34A),
                          bg: Color(0xFFDCFCE7),
                          text: 'HD Video Lessons for Grade 9-12 & TVET',
                        ),
                        SizedBox(height: 10),
                        _FeatureRow(
                          icon: Icons.description_rounded,
                          color: Color(0xFF2563EB),
                          bg: Color(0xFFDBEAFE),
                          text: 'PDF Notes & Study Materials',
                        ),
                        SizedBox(height: 10),
                        _FeatureRow(
                          icon: Icons.quiz_rounded,
                          color: Colors.orange,
                          bg: Color(0xFFFFF7ED),
                          text: 'Interactive Quizzes & Practice Tests',
                        ),
                        SizedBox(height: 10),
                        _FeatureRow(
                          icon: Icons.timer_rounded,
                          color: Colors.purple,
                          bg: Color(0xFFF3E8FF),
                          text: 'Timed Exam Preparation (60s per question)',
                        ),
                        SizedBox(height: 10),
                        _FeatureRow(
                          icon: Icons.download_rounded,
                          color: Colors.teal,
                          bg: Color(0xFFCCFBF1),
                          text: 'Offline Downloads for Anytime Learning',
                        ),
                        SizedBox(height: 10),
                        _FeatureRow(
                          icon: Icons.bookmark_rounded,
                          color: Colors.red,
                          bg: Color(0xFFFEE2E2),
                          text: 'Bookmark & Save Your Progress',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '10+',
                          label: 'Courses',
                          icon: Icons.menu_book_rounded,
                          color: const Color(0xFF16A34A),
                          bg: const Color(0xFFDCFCE7),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: '100+',
                          label: 'Lessons',
                          icon: Icons.play_lesson_rounded,
                          color: const Color(0xFF2563EB),
                          bg: const Color(0xFFDBEAFE),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: '1000+',
                          label: 'Students',
                          icon: Icons.people_rounded,
                          color: Colors.orange,
                          bg: const Color(0xFFFFF7ED),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Developer Card
                  _InfoCard(
                    icon: Icons.code_rounded,
                    iconColor: Colors.purple,
                    iconBg: const Color(0xFFF3E8FF),
                    title: 'About the Developer',
                    content:
                        'EthioClass is developed with ❤️ by a passionate Ethiopian developer committed to '
                        'transforming education through technology. Our goal is to make quality education '
                        'accessible to every student across Ethiopia.',
                  ),
                  const SizedBox(height: 14),

                  // Contact Card
                  _InfoCard(
                    icon: Icons.contact_support_rounded,
                    iconColor: const Color(0xFF2563EB),
                    iconBg: const Color(0xFFDBEAFE),
                    title: 'Contact & Support',
                    customContent: const Column(
                      children: [
                        _ContactRow(
                          icon: Icons.email_rounded,
                          color: Color(0xFF16A34A),
                          bg: Color(0xFFDCFCE7),
                          label: 'Email',
                          value: 'support@ethioclass.com',
                        ),
                        SizedBox(height: 12),
                        _ContactRow(
                          icon: Icons.phone_rounded,
                          color: Color(0xFF2563EB),
                          bg: Color(0xFFDBEAFE),
                          label: 'Phone',
                          value: '+251 900 000 000',
                        ),
                        SizedBox(height: 12),
                        _ContactRow(
                          icon: Icons.telegram,
                          color: Colors.blue,
                          bg: Color(0xFFDBEAFE),
                          label: 'Telegram',
                          value: '@EthioClass',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quote footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: const [
                        Icon(
                          Icons.format_quote_rounded,
                          color: Colors.white54,
                          size: 30,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '"Education is the most powerful weapon\nwhich you can use to change the world."',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            height: 1.65,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '— Nelson Mandela',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    '© 2025 EthioClass. All rights reserved.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Widgets ─────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? content;
  final Widget? customContent;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.content,
    this.customContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (content != null)
            Text(
              content!,
              style: const TextStyle(
                color: AppColors.textMedium,
                fontSize: 13.5,
                height: 1.65,
              ),
            ),
          if (customContent != null) customContent!,
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String text;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.bg,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textDark, fontSize: 13.5),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMedium, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  final String value;

  const _ContactRow({
    required this.icon,
    required this.color,
    required this.bg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.textMedium, fontSize: 11),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
