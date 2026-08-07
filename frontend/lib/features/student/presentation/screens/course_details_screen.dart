import 'package:flutter/material.dart';

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

class CourseDetailsScreen extends StatelessWidget {
  const CourseDetailsScreen({super.key});

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
        title: const Text('Course Details', style: TextStyle(color: CourseColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: CourseColors.textPrimary),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 20),
              const Text(
                'Complete Physics course for Ethiopian Grade 12 students based on the latest curriculum. Learn with high-quality video lessons and practice questions.',
                style: TextStyle(color: CourseColors.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: const [
                    Text('Show more', style: TextStyle(color: CourseColors.primaryBlue, fontSize: 13, fontWeight: FontWeight.w600)),
                    Icon(Icons.keyboard_arrow_down, color: CourseColors.primaryBlue, size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Course Progress', style: TextStyle(color: CourseColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('65% Complete', style: TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: 0.65,
                backgroundColor: CourseColors.border,
                valueColor: const AlwaysStoppedAnimation(CourseColors.yellow),
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
              const SizedBox(height: 24),
              _buildTabs(),
              const SizedBox(height: 16),
              _buildChaptersList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2B5B), Color(0xFF1E50FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: CourseColors.yellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Grade 12', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Physics', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('Grade 12', style: TextStyle(color: Colors.white, fontSize: 24)),
              const SizedBox(height: 20),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(Icons.science, size: 80, color: Colors.white.withOpacity(0.2)), // Placeholder for the 3D graphic
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatItem(icon: Icons.person, label: 'Instructor', value: 'Abel Bekele', isAvatar: true),
        _StatItem(icon: Icons.menu_book, label: 'Lessons', value: '36'),
        _StatItem(icon: Icons.access_time, label: 'Duration', value: '18h 45m'),
        _StatItem(icon: Icons.people_outline, label: 'Students', value: '12.4K'),
      ],
    );
  }

  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _TabItem(label: 'Chapters', isActive: true),
        _TabItem(label: 'About'),
        _TabItem(label: 'Instructor'),
        _TabItem(label: 'Reviews (4.8★)'),
      ],
    );
  }

  Widget _buildChaptersList() {
    return Column(
      children: [
        _ChapterTile(index: 1, title: 'Physical Quantities and Units', subtitle: '5 Lessons • 45 min', isFree: true, isCompleted: true),
        _ChapterTile(index: 2, title: 'Kinematics in One Dimension', subtitle: '6 Lessons • 1h 10m', isFree: true, isCompleted: true),
        _ChapterTile(index: 3, title: 'Dynamics', subtitle: '6 Lessons • 1h 20m', isLocked: true),
        _ChapterTile(index: 4, title: 'Work and Energy', subtitle: '5 Lessons • 55 min', isLocked: true),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: CourseColors.bg,
        border: Border(top: BorderSide(color: CourseColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CourseColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CourseColors.border),
              ),
              child: const Icon(Icons.favorite_border, color: CourseColors.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow, color: Colors.black),
                label: const Text('Continue Learning', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CourseColors.yellow,
                  padding: const EdgeInsets.symmetric(vertical: 18),
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

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isAvatar;

  const _StatItem({required this.icon, required this.label, required this.value, this.isAvatar = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isAvatar)
          const CircleAvatar(radius: 12, backgroundColor: CourseColors.border, child: Icon(Icons.person, size: 14, color: CourseColors.textSecondary))
        else
          Icon(icon, color: CourseColors.textSecondary, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 10)),
            Text(value, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;

  const _TabItem({required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isActive ? CourseColors.yellow : CourseColors.textSecondary,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        if (isActive)
          Container(width: 40, height: 2, color: CourseColors.yellow)
        else
          const SizedBox(height: 2),
      ],
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final int index;
  final String title, subtitle;
  final bool isFree, isCompleted, isLocked;

  const _ChapterTile({
    required this.index,
    required this.title,
    required this.subtitle,
    this.isFree = false,
    this.isCompleted = false,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: CourseColors.primaryBlue, shape: BoxShape.circle),
            child: Center(child: Text('$index', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (isFree)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: CourseColors.success.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
              child: const Text('FREE', style: TextStyle(color: CourseColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          if (isCompleted)
            const Icon(Icons.check_circle, color: CourseColors.success, size: 20)
          else if (isLocked)
            const Icon(Icons.lock, color: CourseColors.yellow, size: 20)
        ],
      ),
    );
  }
}
