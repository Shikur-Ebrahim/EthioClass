import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../core/theme.dart';
import '../../models/category_model.dart';
import '../../models/course_model.dart';
import '../../models/division_model.dart';
import '../../services/course_service.dart';
import '../../services/offline_cache_service.dart';
import 'course_detail_screen.dart';
import '../../widgets/ethioclass_loading.dart';

class CategoryDetailScreen extends StatefulWidget {
  final Category category;
  final Color headerColor;
  final Color iconColor;
  final List<Course>? initialCourses;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.headerColor,
    required this.iconColor,
    this.initialCourses,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  bool _isLoading = true;
  List<Division> _divisions = [];
  List<Course> _courses = [];
  String? _errorMessage;

  // Stats
  int _courseCount = 0;
  int _videoCount = 0;
  int _quizCount = 0;
  int _studentCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialCourses != null && widget.initialCourses!.isNotEmpty) {
      // Passed from home screen — instant display
      _courses = widget.initialCourses!;
      _isLoading = false;
      _fetchBackgroundData();
    } else {
      // Try disk cache first (offline support)
      final diskRaw = OfflineCacheService.instance.loadCoursesSync();
      if (diskRaw != null && diskRaw.isNotEmpty) {
        final allCached = diskRaw.map((e) => Course.fromJson(e)).toList();
        final filtered = allCached
            .where((c) => c.categoryId == widget.category.id)
            .toList();
        if (filtered.isNotEmpty) {
          _courses = filtered;
          _isLoading = false;
          _fetchBackgroundData(); // refresh stats/divisions in background
          return;
        }
      }
      // No cache — fetch from network
      _fetchAll();
    }
  }

  Future<void> _fetchBackgroundData() async {
    try {
      final results = await Future.wait([
        CourseService().getDivisions(categoryId: widget.category.id),
        _fetchStats(),
      ]);
      if (mounted) {
        setState(() {
          _divisions = results[0] as List<Division>;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        CourseService().getDivisions(categoryId: widget.category.id),
        CourseService().getCourses(categoryId: widget.category.id),
        _fetchStats(),
      ]);
      if (mounted) {
        setState(() {
          _divisions = results[0] as List<Division>;
          _courses = results[1] as List<Course>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<dynamic> _fetchStats() async {
    try {
      final res = await http.get(
        Uri.parse(
          '$apiBaseUrl/category-stats?category_id=${widget.category.id}',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _courseCount = data['course_count'] ?? 0;
            _videoCount = data['video_count'] ?? 0;
            _quizCount = data['quiz_count'] ?? 0;
            _studentCount = data['student_count'] ?? 0;
          });
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            backgroundColor: widget.headerColor,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.category.imageUrl != null &&
                      widget.category.imageUrl!.isNotEmpty)
                    CachedNetworkImage(
                      fadeInDuration: Duration.zero,
                      imageUrl: widget.category.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          Container(color: widget.headerColor),
                    )
                  else
                    Container(color: widget.headerColor),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.headerColor.withOpacity(0.3),
                          widget.headerColor.withOpacity(0.8),
                          widget.headerColor.withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -40,
                    top: -40,
                    child: Icon(
                      Icons.category_rounded,
                      size: 200,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 40,
                    right: 20,
                    child: SafeArea(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.category.name,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  widget.category.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.75),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.category_rounded,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats row — real data from DB
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    value: '$_courseCount',
                    label: 'Courses',
                    icon: Icons.book_rounded,
                    color: widget.iconColor,
                  ),
                  _Divider(),
                  _StatItem(
                    value: '$_videoCount',
                    label: 'Videos',
                    icon: Icons.play_circle_rounded,
                    color: const Color(0xFF7C3AED),
                  ),
                  _Divider(),
                  _StatItem(
                    value: '$_quizCount',
                    label: 'Practice Qs',
                    icon: Icons.quiz_rounded,
                    color: const Color(0xFF16A34A),
                  ),
                  _Divider(),
                  _StatItem(
                    value: '$_studentCount',
                    label: 'Students',
                    icon: Icons.people_rounded,
                    color: const Color(0xFFF97316),
                  ),
                ],
              ),
            ),
          ),

          // Courses title
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Courses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),

          // Courses list
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(child: const EthioClassLoading()),
            )
          else if (_errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Failed to load: $_errorMessage',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            )
          else if (_courses.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No courses found in this category yet.',
                    style: TextStyle(color: AppColors.grey),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _CourseTile(
                  course: _courses[i],
                  index: i,
                  iconColor: widget.iconColor,
                  categoryName: widget.category.name,
                ),
                childCount: _courses.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

// Stats item
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMedium),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.greyLight);
  }
}

// Course tile — navigates to CourseDetailScreen
class _CourseTile extends StatelessWidget {
  final Course course;
  final int index;
  final Color iconColor;
  final String categoryName;

  const _CourseTile({
    required this.course,
    required this.index,
    required this.iconColor,
    required this.categoryName,
  });

  static const List<Color> _cardColors = [
    Color(0xFF1B5E20), // dark green
    Color(0xFF4527A0), // deep purple
    Color(0xFFE65100), // deep orange
    Color(0xFF01579B), // deep blue
    Color(0xFF880E4F), // deep pink
  ];

  @override
  Widget build(BuildContext context) {
    final cardColor = _cardColors[index % _cardColors.length];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseDetailScreen(
            course: course,
            index: index,
            categoryName: categoryName,
          ),
        ),
      ),
      child: Container(
        height: 115,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Container(
                width: 115,
                height: 115,
                color: cardColor,
                child:
                    course.thumbnailUrl != null &&
                        course.thumbnailUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        fadeInDuration: Duration.zero,
                        imageUrl: '$apiBaseUrl/media/${course.thumbnailUrl!}',
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.school_rounded,
                          color: Colors.white54,
                          size: 36,
                        ),
                      )
                    : const Icon(
                        Icons.school_rounded,
                        color: Colors.white54,
                        size: 36,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    if (categoryName.isNotEmpty)
                      Builder(
                        builder: (context) {
                          final colors = _getCategoryColors(categoryName);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: colors[0], // Light background
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colors[1], // Dark text
                              ),
                            ),
                          );
                        },
                      ),

                    // Title
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Instructor Name
                    if (course.instructorName.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: AppColors.textMedium,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              course.instructorName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMedium,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    const Spacer(),

                    // Lessons & Duration Row
                    Row(
                      children: [
                        const Icon(
                          Icons.play_circle_outline_rounded,
                          size: 14,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.lessonCount} lessons',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMedium,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.textMedium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.durationMinutes ~/ 60}h ${course.durationMinutes % 60}m',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.grey,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Returns [lightBackground, darkText]
  List<Color> _getCategoryColors(String categoryName) {
    final cat = categoryName.toLowerCase();
    if (cat.contains('freshima')) {
      return const [Color(0xFFFEEBC8), Color(0xFFDD6B20)]; // Orange
    } else if (cat.contains('grad12') || cat.contains('grade 12')) {
      return const [Color(0xFFDBEAFE), Color(0xFF1D4ED8)]; // Blue
    } else if (cat.contains('tvet')) {
      return const [Color(0xFFDCFCE7), Color(0xFF15803D)]; // Green
    } else if (cat.contains('middle')) {
      return const [Color(0xFFFCE7F3), Color(0xFFBE185D)]; // Pink
    } else if (cat.contains('primary')) {
      return const [Color(0xFFFEF3C7), Color(0xFFB45309)]; // Amber
    } else {
      return const [Color(0xFFF3F4F6), Color(0xFF374151)]; // Grey
    }
  }
}
