import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../config/api_config.dart';
import '../../models/course_model.dart';
import '../../models/category_model.dart';
import '../../models/chapter_model.dart';
import '../../models/lesson_model.dart';
import '../../services/course_service.dart';
import '../../services/progress_service.dart';
import 'course_detail_screen.dart';
import 'lesson_detail_screen.dart';
import '../../widgets/ethioclass_loading.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Course> _allCourses = [];
  List<Category> _categories = [];
  bool _loading = true;
  String? _error;

  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _isGridView = false;
  String _sortBy = 'newest';

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        CourseService().getCategories(),
        CourseService().getCourses(),
      ]);
      if (mounted) {
        setState(() {
          _categories = results[0] as List<Category>;
          _allCourses = results[1] as List<Course>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = 'Could not load courses.';
          _loading = false;
        });
    }
  }

  List<Course> get _filtered {
    var list = _allCourses.where((c) {
      final matchCat =
          _selectedCategoryId == null || c.categoryId == _selectedCategoryId;
      final q = _searchQuery.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          c.title.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          c.instructorName.toLowerCase().contains(q);
      return matchCat && matchSearch;
    }).toList();

    switch (_sortBy) {
      case 'popular':
        list.sort((a, b) => b.studentCount.compareTo(a.studentCount));
        break;
      case 'az':
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      default:
        list.sort((a, b) {
          final da = a.createdAt ?? DateTime(2000);
          final db = b.createdAt ?? DateTime(2000);
          return db.compareTo(da);
        });
    }
    return list;
  }

  static const _catColors = [
    Color(0xFF4F63D2),
    Color(0xFFE85D04),
    Color(0xFF2D9CDB),
    Color(0xFF27AE60),
    Color(0xFF9B51E0),
    Color(0xFFEB5757),
    Color(0xFF219653),
    Color(0xFFF2994A),
  ];

  Color _colorForIndex(int i) => _catColors[i % _catColors.length];

  String _formatDuration(int minutes) {
    if (minutes == 0) return '';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  void _openCourse(Course course, int i, {bool autoPlay = false}) async {
    if (!autoPlay) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseDetailScreen(
            course: course,
            index: i,
            categoryName: course.categoryName ?? 'Course',
            autoPlayLast: false,
          ),
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: EthioClassLoading()),
    );

    try {
      final chapters = await CourseService().getChapters(course.id);
      if (chapters.isEmpty) throw Exception('No chapters');

      final lastWatched = ProgressService.instance.getLastWatched(course.id);
      Chapter targetChapter;
      int targetLessonIndex = 0;

      if (lastWatched != null) {
        final String lastChapterId = lastWatched['chapterId'] as String;
        final int lastLessonIndex = lastWatched['lessonIndex'] as int;

        final foundChapter = chapters.cast<Chapter?>().firstWhere(
          (c) => c?.id == lastChapterId,
          orElse: () => null,
        );

        targetChapter = foundChapter ?? chapters.first;
        targetLessonIndex = foundChapter != null ? lastLessonIndex : 0;
      } else {
        targetChapter = chapters.first;
      }

      final lessons = await CourseService().getLessons(targetChapter.id);
      final safeIndex = targetLessonIndex < lessons.length
          ? targetLessonIndex
          : 0;

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LessonDetailScreen(
            courseId: course.id,
            courseTitle: course.title,
            courseThumbnailUrl: course.thumbnailUrl,
            courseTotalLessons: course.lessonCount,
            chapterTitle: targetChapter.title,
            isLocked: false,
            thumbnailUrl: targetChapter.thumbnailUrl,
            chapterNumber: targetChapter.chapterNumber,
            chapterDescription: targetChapter.description,
            lessons: lessons,
            initialLessonIndex: safeIndex,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not resume course: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [_buildSliverHeader()],
        body: _loading
            ? const Center(child: EthioClassLoading())
            : _error != null
            ? _buildError()
            : _filtered.isEmpty
            ? _buildEmpty()
            : _buildScrollableBody(),
      ),
    );
  }

  Course? _getLastWatchedCourse() {
    if (_searchQuery.isNotEmpty || _selectedCategoryId != null) return null;
    final lastCourseId = ProgressService.instance
        .getGlobalLastWatchedCourseId();
    if (lastCourseId != null) {
      try {
        return _allCourses.firstWhere((c) => c.id == lastCourseId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Widget _buildContinueLearningCard(Course course) {
    return GestureDetector(
      onTap: () => _openCourse(course, 0, autoPlay: true),
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9), // Light green background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF81C784), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF81C784).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildThumbnail(
                course,
                AppColors.primary,
                width: 70,
                height: 70,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Jump back into your last lesson',
                    style: TextStyle(fontSize: 12, color: AppColors.textMedium),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 14,
                          color: AppColors.navy,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Resume',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 235,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.navy,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.navy, Color(0xFF2D3A5C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Explore Courses',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${_allCourses.length} courses available',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _toggleBtn(
                              Icons.view_list_rounded,
                              !_isGridView,
                              () => setState(() => _isGridView = false),
                            ),
                            _toggleBtn(
                              Icons.grid_view_rounded,
                              _isGridView,
                              () => setState(() => _isGridView = true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search bar — visible on load, collapses on scroll
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      cursorColor: AppColors.primary,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search courses, instructors...',
                        hintStyle: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Colors.white54,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          color: AppColors.navy,
          child: Column(
            children: [
              // Category chips
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final isAll = i == 0;
                    final cat = isAll ? null : _categories[i - 1];
                    final selected = isAll
                        ? _selectedCategoryId == null
                        : _selectedCategoryId == cat!.id;
                    return GestureDetector(
                      onTap: () => setState(
                        () => _selectedCategoryId = isAll ? null : cat!.id,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            isAll ? 'All' : cat!.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? AppColors.navy : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Sort row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Text(
                      '${_filtered.length} course${_filtered.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.sort_rounded,
                      color: Colors.white60,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        dropdownColor: AppColors.navy,
                        iconEnabledColor: Colors.white60,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'newest',
                            child: Text('Newest'),
                          ),
                          DropdownMenuItem(
                            value: 'popular',
                            child: Text('Popular'),
                          ),
                          DropdownMenuItem(value: 'az', child: Text('A → Z')),
                        ],
                        onChanged: (v) =>
                            setState(() => _sortBy = v ?? 'newest'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleBtn(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: active ? AppColors.navy : Colors.white60,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildScrollableBody() {
    final courses = _filtered;
    final lastCourse = _getLastWatchedCourse();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          if (lastCourse != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(4, 0, 0, 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Continue Learning',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildContinueLearningCard(lastCourse),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(4, 16, 0, 8),
                      child: Text(
                        'All Courses',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (!_isGridView)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                lastCourse == null ? 16 : 8,
                16,
                100,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildListCard(courses[i], i),
                  ),
                  childCount: courses.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                lastCourse == null ? 16 : 8,
                16,
                100,
              ),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildGridCard(courses[i], i),
                  childCount: courses.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.88,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListCard(Course course, int i) {
    final color = _colorForIndex(i);
    return GestureDetector(
      onTap: () => _openCourse(course, i),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
              child: _buildThumbnail(course, color, width: 110, height: 110),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (course.categoryName != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          course.categoryName!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (course.instructorName.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 12,
                            color: AppColors.grey,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              course.instructorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (course.lessonCount > 0) ...[
                          const Icon(
                            Icons.play_circle_outline_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${course.lessonCount} lessons',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMedium,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (course.durationMinutes > 0) ...[
                          const Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: AppColors.grey,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatDuration(course.durationMinutes),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (course.studentCount > 0)
                          Row(
                            children: [
                              const Icon(
                                Icons.group_outlined,
                                size: 12,
                                color: AppColors.grey,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _formatCount(course.studentCount),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.grey,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(Course course, int i) {
    final color = _colorForIndex(i);
    return GestureDetector(
      onTap: () => _openCourse(course, i),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: _buildThumbnail(
                course,
                color,
                width: double.infinity,
                height: 110,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (course.instructorName.isNotEmpty)
                    Text(
                      course.instructorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.grey,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (course.lessonCount > 0) ...[
                        const Icon(
                          Icons.play_circle_outline_rounded,
                          size: 11,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${course.lessonCount} lessons',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (course.durationMinutes > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: AppColors.grey,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatDuration(course.durationMinutes),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (course.studentCount > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.group_outlined,
                              size: 11,
                              color: AppColors.grey,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _formatCount(course.studentCount),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMedium,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(
    Course course,
    Color fallbackColor, {
    required double width,
    required double height,
  }) {
    if (course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty) {
      final url = course.thumbnailUrl!.startsWith('http')
          ? course.thumbnailUrl!
          : '$apiBaseUrl/media/${course.thumbnailUrl!}';
      return CachedNetworkImage(
        fadeInDuration: Duration.zero,
        imageUrl: url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) =>
            _fallbackThumbnail(course, fallbackColor, width, height),
      );
    }
    return _fallbackThumbnail(course, fallbackColor, width, height);
  }

  Widget _fallbackThumbnail(
    Course course,
    Color color,
    double width,
    double height,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_filled_rounded,
                  color: Colors.white70,
                  size: 32,
                ),
                if (course.categoryName != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      course.categoryName!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 60, color: AppColors.grey),
          const SizedBox(height: 12),
          const Text(
            'Could not load courses',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check your connection and try again',
            style: TextStyle(color: AppColors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.navy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 60, color: AppColors.grey),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'No courses match "$_searchQuery"'
                : 'No courses in this category',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => setState(() {
              _searchQuery = '';
              _searchCtrl.clear();
              _selectedCategoryId = null;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Clear Filters',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
