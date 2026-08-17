import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/category_model.dart';
import '../../models/course_model.dart';
import 'course_detail_screen.dart';

class CategoryDetailScreen extends StatefulWidget {
  final Category category;
  final Color headerColor;
  final Color iconColor;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.headerColor,
    required this.iconColor,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  // 0 = Natural, 1 = Social (only for grade12)
  int _selectedStream = 0;

  bool get _hasStreams {
    final name = widget.category.name.toLowerCase();
    return name.contains('grade 12') || name.contains('grad12');
  }

  List<_SubjectItem> _getNaturalSubjects() => const [
        _SubjectItem('Mathematics', '32 Courses • 480 Videos', Icons.calculate_rounded, Color(0xFFE3F0FF), Color(0xFF2563EB)),
        _SubjectItem('Physics', '28 Courses • 420 Videos', Icons.science_rounded, Color(0xFFE8F5E9), Color(0xFF16A34A)),
        _SubjectItem('Chemistry', '26 Courses • 380 Videos', Icons.biotech_rounded, Color(0xFFF3EEFF), Color(0xFF7C3AED)),
        _SubjectItem('Biology', '24 Courses • 320 Videos', Icons.eco_rounded, Color(0xFFE6F9F0), Color(0xFF059669)),
        _SubjectItem('English', '20 Courses • 280 Videos', Icons.menu_book_rounded, Color(0xFFFFF3E0), Color(0xFFF97316)),
        _SubjectItem('Civic', '18 Courses • 240 Videos', Icons.account_balance_rounded, Color(0xFFFFECEC), Color(0xFFDC2626)),
      ];

  List<_SubjectItem> _getSocialSubjects() => const [
        _SubjectItem('History', '22 Courses • 330 Videos', Icons.history_edu_rounded, Color(0xFFF5F0FF), Color(0xFF9333EA)),
        _SubjectItem('Geography', '20 Courses • 290 Videos', Icons.public_rounded, Color(0xFFE3F0FF), Color(0xFF2563EB)),
        _SubjectItem('Economics', '18 Courses • 250 Videos', Icons.bar_chart_rounded, Color(0xFFFFF3E0), Color(0xFFF97316)),
        _SubjectItem('English', '20 Courses • 280 Videos', Icons.menu_book_rounded, Color(0xFFE0F7FA), Color(0xFF0891B2)),
        _SubjectItem('Civic', '18 Courses • 240 Videos', Icons.account_balance_rounded, Color(0xFFFFECEC), Color(0xFFDC2626)),
        _SubjectItem('General Business', '16 Courses • 200 Videos', Icons.business_center_rounded, Color(0xFFE8F5E9), Color(0xFF16A34A)),
      ];

  List<_SubjectItem> _getSubjects() {
    final name = widget.category.name.toLowerCase();
    if (name.contains('grade 12') || name.contains('grad12')) {
      return _selectedStream == 0 ? _getNaturalSubjects() : _getSocialSubjects();
    } else if (name.contains('freshman') || name.contains('freshima')) {
      return const [
        _SubjectItem('Mathematics', '30 Courses • 450 Videos', Icons.calculate_rounded, Color(0xFFE3F0FF), Color(0xFF2563EB)),
        _SubjectItem('Physics', '26 Courses • 390 Videos', Icons.science_rounded, Color(0xFFE8F5E9), Color(0xFF16A34A)),
        _SubjectItem('Chemistry', '22 Courses • 310 Videos', Icons.biotech_rounded, Color(0xFFF3EEFF), Color(0xFF7C3AED)),
        _SubjectItem('Economics', '18 Courses • 250 Videos', Icons.bar_chart_rounded, Color(0xFFFFF3E0), Color(0xFFF97316)),
        _SubjectItem('English', '20 Courses • 290 Videos', Icons.menu_book_rounded, Color(0xFFFFECEC), Color(0xFFDC2626)),
        _SubjectItem('Logic', '14 Courses • 180 Videos', Icons.psychology_rounded, Color(0xFFE0F7FA), Color(0xFF0891B2)),
      ];
    } else {
      return const [
        _SubjectItem('Electrical Installation', '22 Courses • 310 Videos', Icons.electrical_services_rounded, Color(0xFFFFF3E0), Color(0xFFF97316)),
        _SubjectItem('Welding & Fabrication', '18 Courses • 260 Videos', Icons.handyman_rounded, Color(0xFFE3F0FF), Color(0xFF2563EB)),
        _SubjectItem('Plumbing', '16 Courses • 220 Videos', Icons.plumbing_rounded, Color(0xFFE8F5E9), Color(0xFF16A34A)),
        _SubjectItem('IT Support', '20 Courses • 300 Videos', Icons.computer_rounded, Color(0xFFF3EEFF), Color(0xFF7C3AED)),
        _SubjectItem('Automotive', '14 Courses • 180 Videos', Icons.car_repair_rounded, Color(0xFFFFECEC), Color(0xFFDC2626)),
        _SubjectItem('Construction', '12 Courses • 160 Videos', Icons.construction_rounded, Color(0xFFE0F7FA), Color(0xFF0891B2)),
      ];
    }
  }

  _CategoryMeta _getMeta() {
    final name = widget.category.name.toLowerCase();
    if (name.contains('grade 12') || name.contains('grad12')) {
      return const _CategoryMeta(
        subtitle: 'National Exam Preparation',
        description: 'Prepare for your university entrance exam with comprehensive Grade 12 materials.',
        courses: '150+', videos: '2,500+', practiceQs: '15,000+', students: '35K+',
        icon: Icons.school_rounded,
      );
    } else if (name.contains('freshman') || name.contains('freshima')) {
      return const _CategoryMeta(
        subtitle: 'University Entrance',
        description: 'Prepare yourself for a successful university journey with expert guidance.',
        courses: '130+', videos: '2,000+', practiceQs: '12,000+', students: '28K+',
        icon: Icons.account_balance_rounded,
      );
    } else {
      return const _CategoryMeta(
        subtitle: 'Technical & Vocational',
        description: 'Build practical skills for a rewarding career in technology and trades.',
        courses: '100+', videos: '1,430+', practiceQs: '8,000+', students: '18K+',
        icon: Icons.build_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = _getSubjects();
    final meta = _getMeta();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: widget.headerColor,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [widget.headerColor, widget.iconColor.withOpacity(0.9)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(widget.category.name,
                                  style: const TextStyle(
                                      fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                              const SizedBox(height: 6),
                              Text(meta.subtitle,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.85))),
                              const SizedBox(height: 10),
                              Text(meta.description,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.75),
                                      height: 1.5)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(meta.icon, color: Colors.white, size: 44),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Stats ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(value: meta.courses, label: 'Courses', icon: Icons.book_rounded, color: widget.iconColor),
                  _DividerLine(),
                  _StatItem(value: meta.videos, label: 'Videos', icon: Icons.play_circle_rounded, color: const Color(0xFF7C3AED)),
                  _DividerLine(),
                  _StatItem(value: meta.practiceQs, label: 'Practice Qs', icon: Icons.quiz_rounded, color: const Color(0xFF16A34A)),
                  _DividerLine(),
                  _StatItem(value: meta.students, label: 'Students', icon: Icons.people_rounded, color: const Color(0xFFF97316)),
                ],
              ),
            ),
          ),

          // ── Stream Division Selector (Grade 12 only) ──
          if (_hasStreams)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Your Stream',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StreamCard(
                            title: 'Natural',
                            subtitle: 'Science & Math',
                            icon: Icons.science_rounded,
                            gradientColors: const [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                            subjects: 'Math • Physics • Chemistry • Biology',
                            isSelected: _selectedStream == 0,
                            onTap: () => setState(() => _selectedStream = 0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StreamCard(
                            title: 'Social',
                            subtitle: 'Humanities & Arts',
                            icon: Icons.groups_rounded,
                            gradientColors: const [Color(0xFF8E24AA), Color(0xFFBA68C8)],
                            subjects: 'History • Geography • Economics',
                            isSelected: _selectedStream == 1,
                            onTap: () => setState(() => _selectedStream = 1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // ── Subjects title ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  const Text('Subjects',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  if (_hasStreams) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _selectedStream == 0
                            ? const Color(0xFF1E88E5).withOpacity(0.12)
                            : const Color(0xFF8E24AA).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _selectedStream == 0 ? 'Natural' : 'Social',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _selectedStream == 0 ? const Color(0xFF1E88E5) : const Color(0xFF8E24AA),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Subjects list ───────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _SubjectTile(item: subjects[i], index: i),
              childCount: subjects.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

// ── Stream Selection Card ───────────────────────────────────────
class _StreamCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final String subjects;
  final bool isSelected;
  final VoidCallback onTap;

  const _StreamCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.subjects,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                )
              : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? null
              : Border.all(color: AppColors.greyLight, width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
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
                    color: isSelected ? Colors.white.withOpacity(0.25) : gradientColors[0].withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon,
                      color: isSelected ? Colors.white : gradientColors[0], size: 20),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded, color: gradientColors[0], size: 12),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white.withOpacity(0.8) : AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subjects,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white.withOpacity(0.7) : AppColors.grey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat item ──────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMedium)),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.greyLight);
  }
}

// ── Subject tile ───────────────────────────────────────────────
class _SubjectTile extends StatelessWidget {
  final _SubjectItem item;
  final int index;
  const _SubjectTile({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final dummyCourse = Course(
          id: 'preview-${item.name}',
          title: item.name,
          description: 'Explore the complete ${item.name} course. Learn with high-quality video lessons and practice questions tailored for you.',
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CourseDetailScreen(course: dummyCourse, index: index)),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: item.bgColor, borderRadius: BorderRadius.circular(14)),
              child: Icon(item.icon, color: item.iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(item.info,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.grey, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────
class _SubjectItem {
  final String name;
  final String info;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _SubjectItem(this.name, this.info, this.icon, this.bgColor, this.iconColor);
}

class _CategoryMeta {
  final String subtitle;
  final String description;
  final String courses;
  final String videos;
  final String practiceQs;
  final String students;
  final IconData icon;

  const _CategoryMeta({
    required this.subtitle, required this.description,
    required this.courses, required this.videos,
    required this.practiceQs, required this.students,
    required this.icon,
  });
}
