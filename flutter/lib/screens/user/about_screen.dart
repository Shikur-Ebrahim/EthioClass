import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF0F172A),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF064E3B), Color(0xFF16A34A), Color(0xFF22C55E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Decorative circles
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
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
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  // App logo & name
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: Color(0xFF16A34A), size: 52),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'EthioClass',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 16),
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
                  const SizedBox(height: 28),

                  // Mission Card
                  _InfoCard(
                    icon: Icons.flag_rounded,
                    iconColor: const Color(0xFF16A34A),
                    title: 'Our Mission',
                    content:
                        'EthioClass is built to empower Ethiopian students with world-class digital education. '
                        'We believe every student — regardless of location — deserves access to high-quality '
                        'lessons, notes, and exam preparation materials right from their phone.',
                  ),
                  const SizedBox(height: 16),

                  // What We Offer
                  _InfoCard(
                    icon: Icons.auto_awesome_rounded,
                    iconColor: Colors.amber,
                    title: 'What We Offer',
                    content: null,
                    customContent: Column(
                      children: const [
                        _FeatureRow(icon: Icons.play_circle_rounded, color: Color(0xFF16A34A), text: 'HD Video Lessons for Grade 9-12 & TVET'),
                        SizedBox(height: 10),
                        _FeatureRow(icon: Icons.description_rounded, color: Color(0xFF2563EB), text: 'PDF Notes & Study Materials'),
                        SizedBox(height: 10),
                        _FeatureRow(icon: Icons.quiz_rounded, color: Colors.orange, text: 'Interactive Quizzes & Practice Tests'),
                        SizedBox(height: 10),
                        _FeatureRow(icon: Icons.timer_rounded, color: Colors.purple, text: 'Timed Exam Preparation'),
                        SizedBox(height: 10),
                        _FeatureRow(icon: Icons.download_rounded, color: Colors.teal, text: 'Offline Downloads for Anytime Learning'),
                        SizedBox(height: 10),
                        _FeatureRow(icon: Icons.bookmark_rounded, color: Colors.red, text: 'Bookmark & Save Your Progress'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '10+',
                          label: 'Courses',
                          icon: Icons.menu_book_rounded,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: '100+',
                          label: 'Lessons',
                          icon: Icons.play_lesson_rounded,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: '1000+',
                          label: 'Students',
                          icon: Icons.people_rounded,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Developer Card
                  _InfoCard(
                    icon: Icons.code_rounded,
                    iconColor: Colors.purple,
                    title: 'About the Developer',
                    content:
                        'EthioClass is developed with ❤️ by a passionate Ethiopian developer committed to '
                        'transforming education through technology. Our goal is to make quality education '
                        'accessible to every student across Ethiopia.',
                  ),
                  const SizedBox(height: 16),

                  // Contact Card
                  _InfoCard(
                    icon: Icons.contact_support_rounded,
                    iconColor: const Color(0xFF2563EB),
                    title: 'Contact & Support',
                    content: null,
                    customContent: Column(
                      children: [
                        _ContactRow(icon: Icons.email_rounded, color: const Color(0xFF16A34A), label: 'Email', value: 'support@ethioclass.com'),
                        const SizedBox(height: 10),
                        _ContactRow(icon: Icons.phone_rounded, color: const Color(0xFF2563EB), label: 'Phone', value: '+251 900 000 000'),
                        const SizedBox(height: 10),
                        _ContactRow(icon: Icons.telegram, color: Colors.blue, label: 'Telegram', value: '@EthioClass'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tagline footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF064E3B), Color(0xFF16A34A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.format_quote_rounded, color: Colors.white54, size: 32),
                        SizedBox(height: 8),
                        Text(
                          '"Education is the most powerful weapon\nwhich you can use to change the world."',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '— Nelson Mandela',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Copyright
                  Text(
                    '© 2025 EthioClass. All rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
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

// ── Reusable Widgets ──────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? content;
  final Widget? customContent;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.content,
    this.customContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (content != null)
            Text(
              content!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
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
  final String text;

  const _FeatureRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13.5),
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

  const _StatCard({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _ContactRow({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
