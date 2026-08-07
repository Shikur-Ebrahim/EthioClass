import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// COLORS (shared across this file)
// ─────────────────────────────────────────────────────────────
class CourseColors {
  static const bg = Color(0xFF031124);
  static const cardBg = Color(0xFF0B1E36);
  static const primaryBlue = Color(0xFF1E50FF);
  static const yellow = Color(0xFFFFC107);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF8A9AB0);
  static const success = Color(0xFF22C55E);
  static const border = Color(0xFF1E3250);
}

// ─────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────
class CourseDetailsScreen extends StatefulWidget {
  const CourseDetailsScreen({super.key});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  int _activeTab = 0;
  final _tabs = ['Chapters', 'About', 'Instructor', 'Reviews (4.8★)'];

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
        title: const Text('Course Details',
            style: TextStyle(color: CourseColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: CourseColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Header card (always visible)
          _buildHeaderCard(),
          const SizedBox(height: 16),
          // ── Tab bar
          _buildTabBar(),
          // ── Tab content
          Expanded(child: _buildTabContent()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── HEADER CARD ─────────────────────────────────────────────
  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2B5B), Color(0xFF1E50FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: CourseColors.yellow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Grade 12',
                      style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                const Text('Physics\nGrade 12',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
                const SizedBox(height: 8),
                const Text(
                  'Complete Physics course for Ethiopian Grade 12 students based on the latest curriculum.',
                  style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                ),
                const SizedBox(height: 12),
                // Progress
                Row(
                  children: const [
                    Text('Course Progress',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Spacer(),
                    Text('65% Complete',
                        style: TextStyle(color: CourseColors.yellow, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: 0.65,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(CourseColors.yellow),
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 4),
                const Text('32 / 49 Lessons Completed',
                    style: TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: atom graphic placeholder
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.science, size: 56, color: Colors.white30),
          ),
        ],
      ),
    );
  }

  // ── STATS ROW ────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MiniStat(icon: Icons.person, label: 'Instructor', value: 'Abel Bekele', isAvatar: true),
          _MiniStat(icon: Icons.menu_book, label: 'Lessons', value: '36'),
          _MiniStat(icon: Icons.access_time, label: 'Duration', value: '18h 45m'),
          _MiniStat(icon: Icons.people_outline, label: 'Students', value: '12.4K'),
        ],
      ),
    );
  }

  // ── TABS BAR ─────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Column(
      children: [
        _buildStatsRow(),
        const Divider(color: CourseColors.border, height: 1),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final active = i == _activeTab;
              return GestureDetector(
                onTap: () => setState(() => _activeTab = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 24),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: active ? CourseColors.yellow : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    _tabs[i],
                    style: TextStyle(
                      color: active ? CourseColors.yellow : CourseColors.textSecondary,
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const Divider(color: CourseColors.border, height: 1),
      ],
    );
  }

  // ── TAB CONTENT ROUTER ───────────────────────────────────────
  Widget _buildTabContent() {
    switch (_activeTab) {
      case 0:
        return const _ChaptersTab();
      case 1:
        return const _AboutTab();
      case 2:
        return const _InstructorTab();
      case 3:
        return const _ReviewsTab();
      default:
        return const _ChaptersTab();
    }
  }

  // ── BOTTOM BAR ───────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: const BoxDecoration(
        color: CourseColors.bg,
        border: Border(top: BorderSide(color: CourseColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CourseColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CourseColors.border),
              ),
              child: const Icon(Icons.favorite_border, color: CourseColors.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow, color: Colors.black),
                label: const Text('Continue Learning',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CourseColors.yellow,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 0 — CHAPTERS
// ─────────────────────────────────────────────────────────────
class _ChaptersTab extends StatelessWidget {
  const _ChaptersTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _ChapterTile(index: 1, title: 'Physical Quantities and Units', subtitle: '5 Lessons • 45 min', isFree: true, isCompleted: true),
        _ChapterTile(index: 2, title: 'Kinematics in One Dimension', subtitle: '6 Lessons • 1h 10m', isFree: true, isCompleted: true),
        _ChapterTile(index: 3, title: 'Dynamics', subtitle: '6 Lessons • 1h 20m', isLocked: true),
        _ChapterTile(index: 4, title: 'Work and Energy', subtitle: '5 Lessons • 55 min', isLocked: true),
        _ChapterTile(index: 5, title: 'Momentum and Collisions', subtitle: '4 Lessons • 50 min', isLocked: true),
        _ChapterTile(index: 6, title: 'Circular Motion', subtitle: '5 Lessons • 1h', isLocked: true),
      ],
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final int index;
  final String title, subtitle;
  final bool isFree, isCompleted, isLocked;

  const _ChapterTile({
    required this.index, required this.title, required this.subtitle,
    this.isFree = false, this.isCompleted = false, this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(color: CourseColors.primaryBlue, shape: BoxShape.circle),
          child: Center(child: Text('$index',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
          ],
        )),
        if (isFree)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: CourseColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('FREE', style: TextStyle(color: CourseColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        if (isCompleted)
          const Icon(Icons.check_circle, color: CourseColors.success, size: 20)
        else if (isLocked)
          const Icon(Icons.lock, color: CourseColors.yellow, size: 20),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 1 — ABOUT
// ─────────────────────────────────────────────────────────────
class _AboutTab extends StatelessWidget {
  const _AboutTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('About This Course',
            style: TextStyle(color: CourseColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text(
          'This course is designed for Ethiopian Grade 12 students to help them master Physics concepts with easy explanations, real-life examples, and practice questions.',
          style: TextStyle(color: CourseColors.textSecondary, fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 16),
        _BulletItem(text: 'Covers all Grade 12 Physics chapters'),
        _BulletItem(text: 'Video lessons with animations and examples'),
        _BulletItem(text: 'Practice quizzes and chapter tests'),
        _BulletItem(text: 'Exam preparation and model questions'),
        _BulletItem(text: 'Access on mobile and download for offline learning'),
        const SizedBox(height: 24),
        const Text('Course Includes',
            style: TextStyle(color: CourseColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _IncludeItem(icon: Icons.play_circle_outline, label: '36 Video Lessons')),
          Expanded(child: _IncludeItem(icon: Icons.quiz_outlined, label: '12 Quizzes')),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _IncludeItem(icon: Icons.download_outlined, label: 'Offline Access')),
          Expanded(child: _IncludeItem(icon: Icons.card_membership, label: 'Certificate')),
        ]),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        const Icon(Icons.check_circle, color: CourseColors.success, size: 16),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 13))),
      ]),
    );
  }
}

class _IncludeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _IncludeItem({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CourseColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CourseColors.border),
      ),
      child: Row(children: [
        Icon(icon, color: CourseColors.primaryBlue, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 12))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 2 — INSTRUCTOR
// ─────────────────────────────────────────────────────────────
class _InstructorTab extends StatelessWidget {
  const _InstructorTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile row
        Row(children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A6E),
              shape: BoxShape.circle,
              border: Border.all(color: CourseColors.yellow, width: 2),
            ),
            child: const Icon(Icons.person, size: 48, color: Colors.white54),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Text('Abel Bekele',
                    style: TextStyle(color: CourseColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(width: 6),
                Icon(Icons.verified, color: CourseColors.primaryBlue, size: 18),
              ]),
              const SizedBox(height: 4),
              const Text('Physics Instructor',
                  style: TextStyle(color: CourseColors.yellow, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              _InstructorDetail(icon: Icons.school_outlined, text: 'MSc in Physics'),
              _InstructorDetail(icon: Icons.location_city_outlined, text: 'Addis Ababa University'),
              _InstructorDetail(icon: Icons.workspace_premium_outlined, text: '8+ Years Teaching Experience'),
            ],
          )),
        ]),
        const SizedBox(height: 24),
        // Stats
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CourseColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CourseColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _InstructorStat(value: '8+', label: 'Years Exp.', icon: Icons.emoji_events, color: CourseColors.yellow),
              _InstructorStat(value: '120+', label: 'Video Lessons', icon: Icons.play_circle, color: CourseColors.primaryBlue),
              _InstructorStat(value: '12.4K', label: 'Students', icon: Icons.people, color: CourseColors.success),
              _InstructorStat(value: '4.8', label: 'Avg. Rating', icon: Icons.star, color: CourseColors.yellow),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('About Instructor',
            style: TextStyle(color: CourseColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text(
          'Abel Bekele is a passionate Physics teacher with more than 8 years of experience in teaching high school and university students. He specializes in breaking down complex Physics concepts into simple and easy-to-understand lessons.',
          style: TextStyle(color: CourseColors.textSecondary, fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 24),
        const Text('Teaching Experience',
            style: TextStyle(color: CourseColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        const _TimelineItem(
          title: 'Physics Teacher',
          subtitle: 'Addis Ababa Science Academy',
          period: '2018 – Present',
          isFirst: true,
        ),
        const _TimelineItem(
          title: 'Lecturer',
          subtitle: 'Addis Ababa University',
          period: '2016 – 2018',
        ),
        const _TimelineItem(
          title: 'Teaching Assistant',
          subtitle: 'Addis Ababa University',
          period: '2014 – 2016',
          isLast: true,
        ),
      ],
    );
  }
}

class _InstructorDetail extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InstructorDetail({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(children: [
        Icon(icon, color: CourseColors.textSecondary, size: 14),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}

class _InstructorStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _InstructorStat({required this.value, required this.label, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 10), textAlign: TextAlign.center),
    ]);
  }
}

class _TimelineItem extends StatelessWidget {
  final String title, subtitle, period;
  final bool isFirst, isLast;
  const _TimelineItem({
    required this.title, required this.subtitle, required this.period,
    this.isFirst = false, this.isLast = false,
  });
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 24,
          child: Column(children: [
            Container(
              width: 12, height: 12,
              decoration: const BoxDecoration(color: CourseColors.yellow, shape: BoxShape.circle),
            ),
            if (!isLast)
              Expanded(child: Container(width: 2, color: CourseColors.border)),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 3),
              Text(period, style: const TextStyle(color: CourseColors.yellow, fontSize: 11)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 3 — REVIEWS
// ─────────────────────────────────────────────────────────────
class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Rating summary row
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Big score
          Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const Text('4.8',
                style: TextStyle(color: CourseColors.textPrimary, fontSize: 52, fontWeight: FontWeight.bold, height: 1)),
            const SizedBox(height: 6),
            Row(children: List.generate(5, (i) => const Icon(Icons.star, color: CourseColors.yellow, size: 18))),
            const SizedBox(height: 4),
            const Text('(128 Reviews)', style: TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
          ]),
          const SizedBox(width: 24),
          // Bar breakdown
          Expanded(child: Column(
            children: [
              _RatingBar(stars: 5, percentage: 0.87, label: '87%'),
              _RatingBar(stars: 4, percentage: 0.10, label: '10%'),
              _RatingBar(stars: 3, percentage: 0.02, label: '2%'),
              _RatingBar(stars: 2, percentage: 0.01, label: '1%'),
              _RatingBar(stars: 1, percentage: 0.00, label: '0%'),
            ],
          )),
        ]),
        const SizedBox(height: 20),
        // Write a review button
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.edit_outlined, color: CourseColors.yellow, size: 18),
          label: const Text('Write a Review', style: TextStyle(color: CourseColors.yellow, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: CourseColors.yellow),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Top Reviews',
            style: TextStyle(color: CourseColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        _ReviewTile(
          name: 'Yonas Alemu', date: 'May 10, 2024', rating: 5,
          comment: 'Best Physics course! The explanations are super clear and the examples help a lot.',
        ),
        _ReviewTile(
          name: 'Selam Tesfaye', date: 'Apr 28, 2024', rating: 5,
          comment: 'Very well organized and easy to follow. It helped me improve my grades significantly.',
        ),
        _ReviewTile(
          name: 'Abebe K.', date: 'Apr 15, 2024', rating: 4,
          comment: 'Great content and the instructor explains difficult topics in a simple way.',
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {},
          child: const Center(
            child: Text('View All Reviews →',
                style: TextStyle(color: CourseColors.primaryBlue, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _RatingBar extends StatelessWidget {
  final int stars;
  final double percentage;
  final String label;
  const _RatingBar({required this.stars, required this.percentage, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text('$stars', style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
        const SizedBox(width: 4),
        const Icon(Icons.star, color: CourseColors.yellow, size: 11),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: CourseColors.border,
            valueColor: const AlwaysStoppedAnimation(CourseColors.yellow),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(label, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 10)),
        ),
      ]),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final String name, date, comment;
  final int rating;
  const _ReviewTile({required this.name, required this.date, required this.rating, required this.comment});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CourseColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CourseColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const CircleAvatar(radius: 18, backgroundColor: CourseColors.border,
              child: Icon(Icons.person, color: CourseColors.textSecondary, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(name,
                  style: const TextStyle(color: CourseColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: CourseColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Verified', style: TextStyle(color: CourseColors.success, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ]),
          ])),
          Text(date, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
        ]),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) => Icon(Icons.star,
              color: i < rating ? CourseColors.yellow : CourseColors.border, size: 14)),
        ),
        const SizedBox(height: 8),
        Text(comment, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 13, height: 1.5)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED STAT WIDGET
// ─────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isAvatar;
  const _MiniStat({required this.icon, required this.label, required this.value, this.isAvatar = false});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (isAvatar)
        const CircleAvatar(radius: 11, backgroundColor: CourseColors.border,
            child: Icon(Icons.person, size: 13, color: CourseColors.textSecondary))
      else
        Icon(icon, color: CourseColors.textSecondary, size: 15),
      const SizedBox(width: 5),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 9)),
        Text(value, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    ]);
  }
}
