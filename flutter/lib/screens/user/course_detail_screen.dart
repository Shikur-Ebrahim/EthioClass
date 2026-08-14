import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/course_model.dart';
import 'lesson_detail_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  final int index;

  const CourseDetailScreen({
    super.key,
    required this.course,
    required this.index,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _expanded = false;

  static const List<Color> _headerColors = [
    Color(0xFF1B5E20),
    Color(0xFF4527A0),
    Color(0xFFE65100),
    Color(0xFF01579B),
    Color(0xFF880E4F),
  ];

  // Sample chapters data
  static const List<_ChapterItem> _chapters = [
    _ChapterItem('Physical Quantities and Units', '5 Lessons • 45 min', _ChapterState.free),
    _ChapterItem('Kinematics in One Dimension', '6 Lessons • 1h 10m', _ChapterState.free),
    _ChapterItem('Dynamics', '6 Lessons • 1h 20m', _ChapterState.locked),
    _ChapterItem('Work and Energy', '5 Lessons • 55 min', _ChapterState.locked),
    _ChapterItem('Oscillations and Waves', '7 Lessons • 1h 30m', _ChapterState.locked),
    _ChapterItem('Electrostatics', '6 Lessons • 1h 05m', _ChapterState.locked),
    _ChapterItem('Electric Current', '5 Lessons • 50 min', _ChapterState.locked),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headerColor = _headerColors[widget.index % _headerColors.length];
    final description = widget.course.description.isNotEmpty
        ? widget.course.description
        : 'Complete course for Ethiopian students based on the latest curriculum. Learn with high-quality video lessons and practice questions.';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 260,
                  pinned: true,
                  backgroundColor: headerColor,
                  leading: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                    ),
                  ),
                  title: const Text(
                    'Course Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.share_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [headerColor, headerColor.withBlue(headerColor.blue + 40)],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 64, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Category badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Grade 12',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.course.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Instructor + stats
                              Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text('A',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Abel Bekele',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 16),
                                  _HeaderStat(
                                      icon: Icons.play_lesson_rounded,
                                      value: '36',
                                      label: 'Lessons'),
                                  const SizedBox(width: 14),
                                  _HeaderStat(
                                      icon: Icons.access_time_rounded,
                                      value: '18h 45m',
                                      label: 'Duration'),
                                  const SizedBox(width: 14),
                                  _HeaderStat(
                                      icon: Icons.people_rounded,
                                      value: '12.4K',
                                      label: 'Students'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Description ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          maxLines: _expanded ? null : 3,
                          overflow: _expanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMedium,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _expanded = !_expanded),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _expanded ? 'Show less' : 'Show more',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              Icon(
                                _expanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Progress ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Course Progress',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              '66% Complete',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: 0.66,
                            minHeight: 8,
                            backgroundColor: AppColors.greyLight,
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Tabs ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.grey,
                          indicatorColor: AppColors.primary,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelStyle: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                          tabs: const [
                            Tab(text: 'Chapters'),
                            Tab(text: 'About'),
                            Tab(text: 'Instructor'),
                            Tab(text: 'Reviews'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Chapter list ─────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _ChapterTile(
                          chapter: _chapters[i], index: i),
                      childCount: _chapters.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),

          // ── Bottom bar ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.greyLight),
                  ),
                  child: const Icon(Icons.favorite_border_rounded,
                      color: AppColors.textDark),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: const Text(
                      'Continue Learning',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header stat widget ────────────────────────────────────────
class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeaderStat(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 12),
            const SizedBox(width: 3),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        Text(label,
            style:
                const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

// ── Chapter tile ──────────────────────────────────────────────
class _ChapterTile extends StatelessWidget {
  final _ChapterItem chapter;
  final int index;

  const _ChapterTile({required this.chapter, required this.index});

  @override
  Widget build(BuildContext context) {
    final bool isLocked = chapter.state == _ChapterState.locked;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonDetailScreen(
              chapterTitle: chapter.title,
              isLocked: isLocked,
            ),
          ),
        );
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          // Chapter number circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  chapter.info,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Badge
          _buildBadge(chapter.state),
        ],
      ),
    ),
    );
  }

  Widget _buildBadge(_ChapterState state) {
    if (state == _ChapterState.free) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'FREE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.success,
          ),
        ),
      );
    }
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.lock_rounded,
          color: AppColors.grey, size: 16),
    );
  }
}

// ── Data models ────────────────────────────────────────────────
enum _ChapterState { free, locked }

class _ChapterItem {
  final String title;
  final String info;
  final _ChapterState state;

  const _ChapterItem(this.title, this.info, this.state);
}
