import 'package:flutter/material.dart';
import 'course_details_screen.dart'; // To reuse CourseColors

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourseColors.bg,
      appBar: AppBar(
        backgroundColor: CourseColors.bg,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 20, top: 16),
          child: Icon(Icons.bookmark, color: CourseColors.yellow, size: 28),
        ),
        leadingWidth: 48,
        title: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('My Bookmarks', style: TextStyle(color: CourseColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Continue where you left off', style: TextStyle(color: CourseColors.textSecondary, fontSize: 12, fontWeight: FontWeight.normal)),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 16),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: CourseColors.border)),
              child: const Icon(Icons.search, color: CourseColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          _buildFilterChips(),
          const SizedBox(height: 24),
          Expanded(child: _buildBookmarksList()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _FilterChip(label: 'All (8)', isActive: true),
          _FilterChip(label: 'In Progress (5)'),
          _FilterChip(label: 'Videos (6)'),
          _FilterChip(label: 'Notes (2)'),
        ],
      ),
    );
  }

  Widget _buildBookmarksList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _BookmarkTile(
          course: 'Physics - Grade 12',
          title: '1. Physical Quantities and Units',
          progress: 0.75,
          duration: '12:45',
          isFree: true,
        ),
        _BookmarkTile(
          course: 'Physics - Grade 12',
          title: '2. Kinematics in One Dimension',
          progress: 0.60,
          duration: '18:30',
          isFree: true,
          thumbnailColor: const Color(0xFF166534), // Dark Green
        ),
        _BookmarkTile(
          course: 'Physics - Grade 12',
          title: '3. Motion in Two Dimensions',
          progress: 0.30,
          duration: '22:10',
          isLocked: true,
        ),
        _BookmarkTile(
          course: 'Mathematics - Grade 12',
          title: '4. Trigonometry Basics',
          progress: 0.45,
          duration: '16:20',
          isFree: true,
          thumbnailColor: const Color(0xFF4C1D95), // Dark Purple
        ),
        _BookmarkTile(
          course: 'Mathematics - Grade 12',
          title: '5. Quadratic Equations',
          progress: 0.20,
          duration: '20:15',
          isLocked: true,
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
      currentIndex: 3, // Bookmarks active
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Courses'),
        BottomNavigationBarItem(icon: Icon(Icons.download_for_offline_outlined), label: 'Downloads'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Bookmarks'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _FilterChip({required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? CourseColors.yellow.withOpacity(0.15) : CourseColors.cardBg,
        border: Border.all(color: isActive ? CourseColors.yellow : CourseColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? CourseColors.yellow : CourseColors.textSecondary,
          fontSize: 13,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final String course, title, duration;
  final double progress;
  final bool isFree, isLocked;
  final Color? thumbnailColor;

  const _BookmarkTile({
    required this.course,
    required this.title,
    required this.progress,
    required this.duration,
    this.isFree = false,
    this.isLocked = false,
    this.thumbnailColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CourseColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CourseColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with play button
          Container(
            width: 90, height: 70,
            decoration: BoxDecoration(
              color: thumbnailColor ?? CourseColors.primaryBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
                Positioned(
                  bottom: 4, right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                    child: Text(duration, style: const TextStyle(color: Colors.white, fontSize: 9)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Info & Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: CourseColors.border,
                  valueColor: const AlwaysStoppedAnimation(CourseColors.yellow),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 4),
                Text('${(progress * 100).toInt()}% Completed', style: const TextStyle(color: CourseColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          // Badges & Action
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isFree)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: CourseColors.success.withOpacity(0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: CourseColors.success.withOpacity(0.3))),
                  child: const Text('Free', style: TextStyle(color: CourseColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else if (isLocked)
                const Icon(Icons.lock, color: CourseColors.yellow, size: 16),
              
              const SizedBox(height: 16),
              const Icon(Icons.more_vert, color: CourseColors.textSecondary, size: 18),
            ],
          )
        ],
      ),
    );
  }
}
