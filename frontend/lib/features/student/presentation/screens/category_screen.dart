import 'package:flutter/material.dart';
import 'course_details_screen.dart'; // reuse CourseColors

class CategoryScreen extends StatelessWidget {
  final String categoryName;
  final String categorySubtitle;

  const CategoryScreen({
    super.key,
    this.categoryName = 'Freshman',
    this.categorySubtitle = 'University Entrance',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourseColors.bg,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header
          SliverToBoxAdapter(child: _buildHeroHeader(context)),
          // ── Stats row
          SliverToBoxAdapter(child: _buildStatsRow()),
          // ── Subjects label
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text('Subjects',
                  style: TextStyle(color: CourseColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          // ── Subject list
          SliverList(
            delegate: SliverChildListDelegate([
              _SubjectTile(icon: Icons.calculate, label: 'Mathematics', courses: 32, videos: 480, color: const Color(0xFF7C3AED)),
              _SubjectTile(icon: Icons.science, label: 'Physics', courses: 28, videos: 420, color: CourseColors.primaryBlue),
              _SubjectTile(icon: Icons.biotech, label: 'Chemistry', courses: 26, videos: 380, color: CourseColors.success),
              _SubjectTile(icon: Icons.eco, label: 'Biology', courses: 24, videos: 320, color: const Color(0xFF16A34A)),
              _SubjectTile(icon: Icons.text_fields, label: 'English', courses: 20, videos: 280, color: const Color(0xFFF59E0B)),
              _SubjectTile(icon: Icons.history_edu, label: 'History', courses: 18, videos: 240, color: const Color(0xFFEF4444)),
              _SubjectTile(icon: Icons.map, label: 'Geography', courses: 16, videos: 200, color: const Color(0xFF0891B2)),
              const SizedBox(height: 100),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2B5B), Color(0xFF1E50FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Back button
            Positioned(
              top: 8, left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Text content
            Positioned(
              left: 24, bottom: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(categoryName,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1)),
                  const SizedBox(height: 4),
                  Text(categorySubtitle,
                      style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  const Text('Prepare yourself for a successful\nuniversity journey.',
                      style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5)),
                ],
              ),
            ),
            // Character illustration placeholder
            Positioned(
              right: 20, bottom: 0,
              child: Container(
                width: 110, height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Icon(Icons.person, size: 90, color: Colors.white24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CourseColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CourseColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _StatBox(value: '150+', label: 'Courses', icon: Icons.menu_book),
          _StatBox(value: '2,500+', label: 'Videos', icon: Icons.play_circle_outline),
          _StatBox(value: '15,000+', label: 'Practice Qs', icon: Icons.quiz_outlined),
          _StatBox(value: '35K+', label: 'Students', icon: Icons.people_outline),
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
      currentIndex: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Courses'),
        BottomNavigationBarItem(icon: Icon(Icons.download_for_offline_outlined), label: 'Downloads'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: 'Bookmarks'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _StatBox({required this.value, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: CourseColors.textSecondary, size: 20),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 10)),
    ]);
  }
}

class _SubjectTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int courses, videos;
  final Color color;
  const _SubjectTile({required this.icon, required this.label, required this.courses, required this.videos, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CourseColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CourseColors.border),
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: CourseColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('$courses Courses • $videos Videos',
                  style: const TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
            ],
          )),
          const Icon(Icons.chevron_right, color: CourseColors.textSecondary),
        ]),
      ),
    );
  }
}
