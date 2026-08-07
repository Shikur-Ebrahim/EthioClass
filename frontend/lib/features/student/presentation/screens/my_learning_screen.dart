import 'package:flutter/material.dart';
import 'course_details_screen.dart';

class MyLearningScreen extends StatefulWidget {
  const MyLearningScreen({super.key});

  @override
  State<MyLearningScreen> createState() => _MyLearningScreenState();
}

class _MyLearningScreenState extends State<MyLearningScreen> {
  int _activeTab = 0;
  final _tabs = ['In Progress', 'Completed', 'Saved'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourseColors.bg,
      appBar: AppBar(
        backgroundColor: CourseColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: CourseColors.textPrimary, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('My Learning',
            style: TextStyle(color: CourseColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.search, color: CourseColors.textSecondary), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // ── Filter pill tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: CourseColors.cardBg,
                border: Border.all(color: CourseColors.border),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final active = i == _activeTab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: active ? CourseColors.yellow : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _tabs[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: active ? Colors.black : CourseColors.textSecondary,
                            fontSize: 13,
                            fontWeight: active ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildTabContent()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 0: return _buildInProgress();
      case 1: return _buildCompleted();
      case 2: return _buildSaved();
      default: return _buildInProgress();
    }
  }

  // ── IN PROGRESS TAB ──────────────────────────────────────────
  Widget _buildInProgress() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: const [
        _LearningCard(title: 'Physics \u2013 Grade 12', instructor: 'Abel Bekele', progress: 0.65, lastInfo: 'Last accessed: Today', thumbColor: Color(0xFF1E50FF), thumbIcon: Icons.science),
        _LearningCard(title: 'Mathematics \u2013 Grade 12', instructor: 'Mesfin Tadesse', progress: 0.40, lastInfo: 'Last accessed: Yesterday', thumbColor: Color(0xFF7C3AED), thumbIcon: Icons.calculate),
        _LearningCard(title: 'Chemistry \u2013 Grade 12', instructor: 'Rahel Worku', progress: 0.25, lastInfo: 'Last accessed: 2 days ago', thumbColor: Color(0xFF059669), thumbIcon: Icons.biotech),
        _LearningCard(title: 'Biology \u2013 Grade 12', instructor: 'Yonatan Alemu', progress: 0.75, lastInfo: 'Last accessed: 3 days ago', thumbColor: Color(0xFF16A34A), thumbIcon: Icons.eco),
        _LearningCard(title: 'Engineering Drawing \u2013 TVET', instructor: 'Samuel Getachew', progress: 0.30, lastInfo: 'Last accessed: 5 days ago', thumbColor: Color(0xFFF59E0B), thumbIcon: Icons.architecture),
      ],
    );
  }

  // ── COMPLETED TAB ─────────────────────────────────────────────
  Widget _buildCompleted() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // "Great Job" banner
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CourseColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CourseColors.border),
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: CourseColors.yellow.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events, color: CourseColors.yellow, size: 26),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Great Job! 🎉',
                    style: TextStyle(color: CourseColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('You have completed 12 courses',
                    style: TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
              ]),
            ),
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: CourseColors.primaryBlue.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: CourseColors.primaryBlue.withOpacity(0.3)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                Text('12', style: TextStyle(color: CourseColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Courses', style: TextStyle(color: CourseColors.textSecondary, fontSize: 9)),
              ]),
            ),
          ]),
        ),
        // Completed course cards
        const _LearningCard(title: 'Physics \u2013 Grade 12', instructor: 'Abel Bekele', progress: 1.0, lastInfo: 'Completed on May 12, 2024', thumbColor: Color(0xFF1E50FF), thumbIcon: Icons.science, isCompleted: true),
        const _LearningCard(title: 'Mathematics \u2013 Grade 12', instructor: 'Mesfin Tadesse', progress: 1.0, lastInfo: 'Completed on May 5, 2024', thumbColor: Color(0xFF7C3AED), thumbIcon: Icons.calculate, isCompleted: true),
        const _LearningCard(title: 'Chemistry \u2013 Grade 12', instructor: 'Rahel Worku', progress: 1.0, lastInfo: 'Completed on Apr 28, 2024', thumbColor: Color(0xFF059669), thumbIcon: Icons.biotech, isCompleted: true),
        const _LearningCard(title: 'Biology \u2013 Grade 12', instructor: 'Yonatan Alemu', progress: 1.0, lastInfo: 'Completed on Apr 20, 2024', thumbColor: Color(0xFF16A34A), thumbIcon: Icons.eco, isCompleted: true),
        const _LearningCard(title: 'Engineering Drawing \u2013 TVET', instructor: 'Samuel Getachew', progress: 1.0, lastInfo: 'Completed on Apr 10, 2024', thumbColor: Color(0xFF0891B2), thumbIcon: Icons.architecture, isCompleted: true),
      ],
    );
  }

  // ── SAVED TAB ─────────────────────────────────────────────────
  Widget _buildSaved() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // "Saved for Later" banner
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CourseColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CourseColors.border),
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: CourseColors.primaryBlue.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark, color: CourseColors.primaryBlue, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Saved for Later',
                    style: TextStyle(color: CourseColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Access your saved courses and\nlessons anytime.',
                    style: TextStyle(color: CourseColors.textSecondary, fontSize: 12, height: 1.4)),
              ]),
            ),
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: CourseColors.primaryBlue.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: CourseColors.primaryBlue.withOpacity(0.3)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                Text('8', style: TextStyle(color: CourseColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Items', style: TextStyle(color: CourseColors.textSecondary, fontSize: 9)),
              ]),
            ),
          ]),
        ),
        // Saved lesson tiles
        const _SavedTile(title: 'Physics \u2013 Grade 12', chapter: 'Chapter 3: Laws of Motion', duration: '24:30', thumbColor: Color(0xFF1E50FF), thumbIcon: Icons.science),
        const _SavedTile(title: 'Mathematics \u2013 Grade 12', chapter: 'Chapter 2: Derivatives', duration: '18:45', thumbColor: Color(0xFF7C3AED), thumbIcon: Icons.calculate),
        const _SavedTile(title: 'Chemistry \u2013 Grade 12', chapter: 'Chapter 1: Atomic Structure', duration: '15:20', thumbColor: Color(0xFF059669), thumbIcon: Icons.biotech),
        const _SavedTile(title: 'Biology \u2013 Grade 12', chapter: 'Chapter 4: Cell Division', duration: '19:10', thumbColor: Color(0xFF16A34A), thumbIcon: Icons.eco),
        const _SavedTile(title: 'Engineering Drawing \u2013 TVET', chapter: 'Orthographic Projection', duration: '21:30', thumbColor: Color(0xFF0891B2), thumbIcon: Icons.architecture),
        // Footer hint
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 24),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CourseColors.primaryBlue.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CourseColors.primaryBlue.withOpacity(0.2)),
          ),
          child: Row(children: const [
            Icon(Icons.info_outline, color: CourseColors.primaryBlue, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Saved items will appear here',
                    style: TextStyle(color: CourseColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                SizedBox(height: 3),
                Text('Bookmark courses or lessons to save them for later.',
                    style: TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
              ]),
            ),
          ]),
        ),
      ],
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
// LEARNING CARD (In Progress + Completed)
// ─────────────────────────────────────────────────────────────
class _LearningCard extends StatelessWidget {
  final String title, instructor, lastInfo;
  final double progress;
  final Color thumbColor;
  final IconData thumbIcon;
  final bool isCompleted;

  const _LearningCard({
    required this.title, required this.instructor, required this.progress,
    required this.lastInfo, required this.thumbColor, required this.thumbIcon,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CourseColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CourseColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Thumbnail
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [thumbColor, thumbColor.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(thumbIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(color: CourseColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(instructor, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
          ])),
          // Badge + menu
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isCompleted
                    ? CourseColors.success.withOpacity(0.15)
                    : CourseColors.primaryBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isCompleted ? 'Completed' : 'In Progress',
                style: TextStyle(
                  color: isCompleted ? CourseColors.success : CourseColors.primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Icon(Icons.more_vert, color: CourseColors.textSecondary, size: 18),
          ]),
        ]),
        const SizedBox(height: 14),
        // Progress bar
        LinearProgressIndicator(
          value: progress,
          backgroundColor: CourseColors.border,
          valueColor: AlwaysStoppedAnimation(isCompleted ? CourseColors.yellow : CourseColors.yellow),
          minHeight: 5,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 8),
        // Bottom row
        Row(children: [
          if (!isCompleted) ...[
            const Icon(Icons.access_time, color: CourseColors.textSecondary, size: 13),
            const SizedBox(width: 5),
          ],
          Expanded(
            child: Text(lastInfo,
                style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
                color: CourseColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SAVED TILE
// ─────────────────────────────────────────────────────────────
class _SavedTile extends StatelessWidget {
  final String title, chapter, duration;
  final Color thumbColor;
  final IconData thumbIcon;

  const _SavedTile({
    required this.title, required this.chapter, required this.duration,
    required this.thumbColor, required this.thumbIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CourseColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CourseColors.border),
      ),
      child: Row(children: [
        // Thumbnail
        Container(
          width: 54, height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [thumbColor, thumbColor.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(thumbIcon, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(color: CourseColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(chapter,
              style: const TextStyle(color: CourseColors.textSecondary, fontSize: 12),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.play_circle_outline, color: CourseColors.textSecondary, size: 13),
            const SizedBox(width: 4),
            Text('Video Lesson • $duration',
                style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
          ]),
        ])),
        // Bookmark + menu
        Column(children: const [
          Icon(Icons.bookmark_border, color: CourseColors.textSecondary, size: 20),
          SizedBox(height: 12),
          Icon(Icons.more_vert, color: CourseColors.textSecondary, size: 18),
        ]),
      ]),
    );
  }
}
