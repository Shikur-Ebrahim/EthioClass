import 'package:flutter/material.dart';
import 'course_details_screen.dart'; // reuse CourseColors

// ─────────────────────────────────────────────────────────────
// ROOT: Bookmarks Screen with 4 Filter Tabs
// ─────────────────────────────────────────────────────────────
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  int _selectedTab = 0;

  static const _tabs = ['All (8)', 'In Progress (5)', 'Videos (6)', 'Notes (2)'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourseColors.bg,
      appBar: AppBar(
        backgroundColor: CourseColors.bg,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 20, top: 4),
          child: Icon(Icons.bookmark, color: CourseColors.yellow, size: 28),
        ),
        leadingWidth: 48,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('My Bookmarks',
                style: TextStyle(color: CourseColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            Text('Continue where you left off',
                style: TextStyle(color: CourseColors.textSecondary, fontSize: 11, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: CourseColors.border)),
                child: const Icon(Icons.search, color: CourseColors.textSecondary, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // ── Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final active = i == _selectedTab;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: active ? CourseColors.yellow.withOpacity(0.15) : CourseColors.cardBg,
                      border: Border.all(color: active ? CourseColors.yellow : CourseColors.border),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_tabs[i],
                        style: TextStyle(
                          color: active ? CourseColors.yellow : CourseColors.textSecondary,
                          fontSize: 13,
                          fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        )),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          // ── Content
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_selectedTab) {
      case 1:
        return const _InProgressTab();
      case 2:
        return const _VideosTab();
      case 3:
        return const _NotesTab();
      default:
        return const _AllBookmarksTab();
    }
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: CourseColors.bg,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: CourseColors.yellow,
      unselectedItemColor: CourseColors.textSecondary,
      currentIndex: 3,
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

// ─────────────────────────────────────────────────────────────
// TAB 0 — ALL BOOKMARKS
// ─────────────────────────────────────────────────────────────
class _AllBookmarksTab extends StatelessWidget {
  const _AllBookmarksTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _BookmarkCard(course: 'Physics - Grade 12', title: '1. Physical Quantities and Units', progress: 0.75, duration: '12:45', isFree: true),
        _BookmarkCard(course: 'Physics - Grade 12', title: '2. Kinematics in One Dimension', progress: 0.60, duration: '18:30', isFree: true, thumbColor: const Color(0xFF166534)),
        _BookmarkCard(course: 'Physics - Grade 12', title: '3. Motion in Two Dimensions', progress: 0.30, duration: '22:10', isLocked: true),
        _BookmarkCard(course: 'Mathematics - Grade 12', title: '4. Trigonometry Basics', progress: 0.45, duration: '16:20', isFree: true, thumbColor: const Color(0xFF4C1D95)),
        _BookmarkCard(course: 'Mathematics - Grade 12', title: '5. Quadratic Equations', progress: 0.20, duration: '20:15', isLocked: true),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 1 — IN PROGRESS
// ─────────────────────────────────────────────────────────────
class _InProgressTab extends StatelessWidget {
  const _InProgressTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Pick up where you left off',
              style: TextStyle(color: CourseColors.textSecondary, fontSize: 13)),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: const [
              _InProgressCard(
                course: 'Physics - Grade 12',
                title: '1. Physical Quantities and Units',
                progress: 0.75,
                lastWatched: 'Today',
                thumbColor: Color(0xFF1E50FF),
              ),
              _InProgressCard(
                course: 'Physics - Grade 12',
                title: '2. Kinematics in One Dimension',
                progress: 0.60,
                lastWatched: 'Yesterday',
                thumbColor: Color(0xFF166534),
              ),
              _InProgressCard(
                course: 'Physics - Grade 12',
                title: '3. Motion in Two Dimensions',
                progress: 0.30,
                lastWatched: '2 days ago',
                thumbColor: Color(0xFF1E3A6E),
              ),
              _InProgressCard(
                course: 'Mathematics - Grade 12',
                title: '4. Trigonometry Basics',
                progress: 0.45,
                lastWatched: '3 days ago',
                thumbColor: Color(0xFF4C1D95),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InProgressCard extends StatelessWidget {
  final String course, title, lastWatched;
  final double progress;
  final Color thumbColor;

  const _InProgressCard({
    required this.course,
    required this.title,
    required this.progress,
    required this.lastWatched,
    required this.thumbColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CourseColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CourseColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Container(
                width: 80, height: 65,
                decoration: BoxDecoration(color: thumbColor, borderRadius: BorderRadius.circular(10)),
                child: Stack(
                  children: [
                    const Center(child: Icon(Icons.science, color: Colors.white54, size: 32)),
                    Positioned(
                      bottom: 4, right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                        child: const Text('12:45', style: TextStyle(color: Colors.white, fontSize: 9)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(title,
                        style: const TextStyle(color: CourseColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 2),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: CourseColors.primaryBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('In Progress',
                          style: TextStyle(color: CourseColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, color: CourseColors.textSecondary, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: CourseColors.border,
            valueColor: const AlwaysStoppedAnimation(CourseColors.yellow),
            minHeight: 5,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 4),
          Text('${(progress * 100).toInt()}%',
              style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, color: CourseColors.textSecondary, size: 14),
                  const SizedBox(width: 4),
                  Text('Last watched: $lastWatched',
                      style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow, color: Colors.black, size: 14),
                label: const Text('Continue', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CourseColors.yellow,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 2 — VIDEOS
// ─────────────────────────────────────────────────────────────
class _VideosTab extends StatefulWidget {
  const _VideosTab();

  @override
  State<_VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<_VideosTab> {
  int _activeFilter = 0;
  final _filters = ['All Videos (36)', 'Completed (12)', 'Not Watched (24)'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Course header card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CourseColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CourseColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E50FF), Color(0xFF0F2B5B)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.science, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Physics – Grade 12',
                      style: TextStyle(color: CourseColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                  Text('36 Lessons • 18h 45m',
                      style: TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
                ]),
              ),
              Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 48, height: 48,
                  child: CircularProgressIndicator(
                    value: 0.65,
                    backgroundColor: CourseColors.border,
                    valueColor: const AlwaysStoppedAnimation(CourseColors.yellow),
                    strokeWidth: 4,
                  ),
                ),
                const Text('65%',
                    style: TextStyle(color: CourseColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Sub-filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: List.generate(_filters.length, (i) {
              final active = i == _activeFilter;
              return GestureDetector(
                onTap: () => setState(() => _activeFilter = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? CourseColors.yellow.withOpacity(0.15) : CourseColors.cardBg,
                    border: Border.all(color: active ? CourseColors.yellow : CourseColors.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_filters[i],
                      style: TextStyle(
                        color: active ? CourseColors.yellow : CourseColors.textSecondary,
                        fontSize: 12,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      )),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: const [
              _VideoLessonTile(index: 1, title: 'Physical Quantities and Units', duration: '12:45', status: _VideoStatus.watched, isFree: true),
              _VideoLessonTile(index: 2, title: 'Kinematics in One Dimension', duration: '18:30', status: _VideoStatus.watched, isFree: true),
              _VideoLessonTile(index: 3, title: 'Motion in Two Dimensions', duration: '22:10', status: _VideoStatus.inProgress, isLocked: true),
              _VideoLessonTile(index: 4, title: 'Laws of Motion', duration: '20:15', status: _VideoStatus.notStarted, isLocked: true),
              _VideoLessonTile(index: 5, title: 'Friction', duration: '15:40', status: _VideoStatus.notStarted, isLocked: true),
              _VideoLessonTile(index: 6, title: 'Work and Energy', duration: '20:30', status: _VideoStatus.notStarted, isLocked: true),
            ],
          ),
        ),
      ],
    );
  }
}

enum _VideoStatus { watched, inProgress, notStarted }

class _VideoLessonTile extends StatelessWidget {
  final int index;
  final String title, duration;
  final _VideoStatus status;
  final bool isFree, isLocked;

  static const _thumbColors = [
    Color(0xFF1E50FF), Color(0xFF166534), Color(0xFF1E3A6E),
    Color(0xFF7C3AED), Color(0xFF065F46), Color(0xFFB45309),
  ];

  const _VideoLessonTile({
    required this.index, required this.title, required this.duration,
    required this.status, this.isFree = false, this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _thumbColors[(index - 1) % _thumbColors.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CourseColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CourseColors.border),
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 90, height: 65,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Stack(
              children: [
                Center(child: Text(title.split(' ').take(3).join('\n').toUpperCase(),
                    style: const TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center)),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$index. $title',
                    style: const TextStyle(color: CourseColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 2),
                const SizedBox(height: 6),
                Row(children: [
                  Text(duration, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
                  const Text(' • ', style: TextStyle(color: CourseColors.textSecondary)),
                  if (status == _VideoStatus.watched)
                    const Text('Watched', style: TextStyle(color: CourseColors.success, fontSize: 11))
                  else if (status == _VideoStatus.inProgress)
                    const Text('In Progress', style: TextStyle(color: CourseColors.primaryBlue, fontSize: 11))
                  else
                    const Text('Not Started', style: TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
                ]),
                if (isFree)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: CourseColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Free', style: TextStyle(color: CourseColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          if (status == _VideoStatus.watched)
            const Icon(Icons.check_circle, color: CourseColors.success, size: 20)
          else if (isLocked)
            const Icon(Icons.lock, color: CourseColors.yellow, size: 18)
          else
            const Icon(Icons.more_vert, color: CourseColors.textSecondary, size: 18),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 3 — NOTES
// ─────────────────────────────────────────────────────────────
class _NotesTab extends StatefulWidget {
  const _NotesTab();

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  int _activeFilter = 0;
  final _filters = ['All Notes (18)', 'My Notes (12)', 'Bookmarks (6)'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Course header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CourseColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CourseColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E50FF), Color(0xFF0F2B5B)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.science, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Physics – Grade 12',
                      style: TextStyle(color: CourseColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                  Text('18 Notes',
                      style: TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
                ]),
              ),
              const Icon(Icons.article_outlined, color: CourseColors.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Sub-filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: List.generate(_filters.length, (i) {
              final active = i == _activeFilter;
              return GestureDetector(
                onTap: () => setState(() => _activeFilter = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? CourseColors.yellow.withOpacity(0.15) : CourseColors.cardBg,
                    border: Border.all(color: active ? CourseColors.yellow : CourseColors.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_filters[i],
                      style: TextStyle(
                        color: active ? CourseColors.yellow : CourseColors.textSecondary,
                        fontSize: 12,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      )),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Chapter Notes',
                style: TextStyle(color: CourseColors.textPrimary.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: const [
              _NoteTile(title: 'Physical Quantities and Units Summary', pages: 12, author: 'My Note', lastUpdated: 'Today', color: Color(0xFF2563EB), isFree: true),
              _NoteTile(title: 'Kinematics in One Dimension Key Formulas', pages: 8, author: 'My Note', lastUpdated: 'Yesterday', color: Color(0xFF16A34A), isFree: true),
              _NoteTile(title: 'Motion in Two Dimensions Important Points', pages: 6, author: 'EthioClass Note', lastUpdated: '2 days ago', color: Color(0xFFF59E0B), isLocked: true),
              _NoteTile(title: 'Laws of Motion Class Notes', pages: 10, author: 'EthioClass Note', lastUpdated: '3 days ago', color: Color(0xFF7C3AED), isLocked: true),
              _NoteTile(title: 'Work and Energy Quick Revision', pages: 7, author: 'EthioClass Note', lastUpdated: '4 days ago', color: Color(0xFF2563EB), isLocked: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoteTile extends StatelessWidget {
  final String title, author, lastUpdated;
  final int pages;
  final Color color;
  final bool isFree, isLocked;

  const _NoteTile({
    required this.title,
    required this.pages,
    required this.author,
    required this.lastUpdated,
    required this.color,
    this.isFree = false,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CourseColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CourseColors.border),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.description_outlined, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(color: CourseColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 2),
                  ),
                  if (isFree)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CourseColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Free', style: TextStyle(color: CourseColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ]),
                const SizedBox(height: 5),
                Text('$pages pages • $author',
                    style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 3),
                Text('Updated: $lastUpdated',
                    style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
                if (isLocked)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Locked',
                        style: TextStyle(color: CourseColors.yellow, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(children: [
            if (isLocked)
              const Icon(Icons.lock, color: CourseColors.yellow, size: 18)
            else
              const Icon(Icons.more_vert, color: CourseColors.textSecondary, size: 18),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED: All-tab bookmark card
// ─────────────────────────────────────────────────────────────
class _BookmarkCard extends StatelessWidget {
  final String course, title, duration;
  final double progress;
  final bool isFree, isLocked;
  final Color? thumbColor;

  const _BookmarkCard({
    required this.course, required this.title, required this.duration,
    required this.progress, this.isFree = false, this.isLocked = false, this.thumbColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CourseColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CourseColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 90, height: 70,
            decoration: BoxDecoration(
              color: thumbColor ?? CourseColors.primaryBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(alignment: Alignment.center, children: [
              const Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
              Positioned(bottom: 4, right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                  child: Text(duration, style: const TextStyle(color: Colors.white, fontSize: 9)),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(course, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
              const SizedBox(height: 4),
              Text(title,
                  style: const TextStyle(color: CourseColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                  maxLines: 2),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: CourseColors.border,
                valueColor: const AlwaysStoppedAnimation(CourseColors.yellow),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(height: 4),
              Text('${(progress * 100).toInt()}% Completed',
                  style: const TextStyle(color: CourseColors.textSecondary, fontSize: 10)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (isFree)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CourseColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Free', style: TextStyle(color: CourseColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            else if (isLocked)
              const Icon(Icons.lock, color: CourseColors.yellow, size: 16),
            const SizedBox(height: 14),
            const Icon(Icons.more_vert, color: CourseColors.textSecondary, size: 18),
          ]),
        ],
      ),
    );
  }
}
