import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../config/api_config.dart';
import '../../services/bookmark_service.dart';
import '../../models/lesson_model.dart';
import '../../models/course_model.dart';
import 'lesson_detail_screen.dart';
import 'course_detail_screen.dart';
import '../../widgets/ethioclass_loading.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _lessons = [];
  List<dynamic> _courses = [];

  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookmarks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await BookmarkService.instance.getBookmarks();
      if (mounted) {
        setState(() {
          _lessons = data['lessons'] ?? [];
          _courses = data['courses'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('socketexception') ||
              errorStr.contains('failed host lookup')) {
            _error = 'No internet connection.';
          } else {
            _error = 'Failed to load bookmarks.';
          }
        });
      }
    }
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  Future<void> _removeLessonBookmark(String lessonId) async {
    try {
      await BookmarkService.instance.removeLessonBookmark(lessonId);
      _loadBookmarks();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove bookmark')),
        );
    }
  }

  Future<void> _removeCourseBookmark(String courseId) async {
    try {
      await BookmarkService.instance.removeCourseBookmark(courseId);
      _loadBookmarks();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove bookmark')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLessons = _searchQuery.isEmpty
        ? _lessons
        : _lessons
              .where(
                (l) => (l['title'] ?? '').toString().toLowerCase().contains(
                  _searchQuery,
                ),
              )
              .toList();

    final filteredCourses = _searchQuery.isEmpty
        ? _courses
        : _courses
              .where(
                (c) => (c['title'] ?? '').toString().toLowerCase().contains(
                  _searchQuery,
                ),
              )
              .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [_buildSliverHeader()],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: EthioClassLoading())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              size: 64,
                              color: AppColors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textMedium,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _loadBookmarks,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              child: const Text(
                                'Retry',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCoursesTab(filteredCourses),
                        _buildLessonsTab(filteredLessons),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    final int totalCount = _lessons.length + _courses.length;
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bookmarks',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Your saved content',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isLoading && totalCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.bookmark,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$totalCount Saved',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _applySearch,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search bookmarks...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.white.withOpacity(0.6),
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: Colors.white.withOpacity(0.6),
                                size: 18,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                _applySearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(
            12,
          ), // slightly reduced for the outer container too
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(
              8,
            ), // Reduced radius for a more rectangular, attractive look
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textMedium,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: 'Courses (${_courses.length})'),
            Tab(text: 'Lessons (${_lessons.length})'),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsTab(List<dynamic> lessons) {
    if (lessons.isEmpty) {
      return _buildEmptyState(
        icon: Icons.play_lesson_outlined,
        title: 'No Lesson Bookmarks',
        subtitle:
            'Save important lessons while watching them\nto easily find them later.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadBookmarks,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        itemCount: lessons.length,
        itemBuilder: (context, index) {
          final l = lessons[index];
          return _buildLessonCard(l);
        },
      ),
    );
  }

  Widget _buildCoursesTab(List<dynamic> courses) {
    if (courses.isEmpty) {
      return _buildEmptyState(
        icon: Icons.school_outlined,
        title: 'No Course Bookmarks',
        subtitle: 'Save courses you want to take in the future.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadBookmarks,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final c = courses[index];
          return _buildCourseCard(c);
        },
      ),
    );
  }

  Widget _buildLessonCard(dynamic l) {
    final thumbUrl = l['thumbnail_url'] ?? l['course_thumbnail_url'];

    // Create Lesson object for navigation
    final lessonObj = Lesson(
      id: l['id'],
      chapterId: l['chapter_id'],
      title: l['title'],
      thumbnailUrl: l['thumbnail_url'],
      videoUrl: l['video_url'],
      notesUrl: l['notes_url'],
      lessonNumber: l['lesson_number'],
      durationMinutes: l['duration_minutes'],
    );

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonDetailScreen(
              lessons: [lessonObj], // Just pass this single lesson for now
              chapterTitle: l['chapter_title'] ?? 'Chapter',
              chapterDescription: '',
              courseTitle: l['course_title'] ?? 'Course',
              courseThumbnailUrl: l['course_thumbnail_url'] ?? '',
              thumbnailUrl: thumbUrl ?? '',
              initialLessonIndex: 0,
            ),
          ),
        ).then((_) => _loadBookmarks());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 100,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: thumbUrl != null && thumbUrl.isNotEmpty
                        ? CachedNetworkImage(
                            fadeInDuration: Duration.zero,
                            imageUrl: '$apiBaseUrl/media/$thumbUrl',
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(
                                Icons.ondemand_video_rounded,
                                color: AppColors.grey,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.ondemand_video_rounded,
                              color: AppColors.grey,
                            ),
                          ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${l['duration_minutes']}m',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l['title'] ?? 'Lesson',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l['course_title'] ?? 'Course',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l['chapter_title'] ?? 'Chapter',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            // Remove button
            IconButton(
              icon: const Icon(
                Icons.bookmark_remove_rounded,
                color: Colors.amber,
                size: 24,
              ),
              onPressed: () => _removeLessonBookmark(l['id']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(dynamic c) {
    final thumbUrl = c['thumbnail_url'];

    // Create minimal course object
    final courseObj = Course(
      id: c['id'],
      categoryId: c['category_id'] ?? '',
      categoryName: c['category_name'] ?? 'Category',
      title: c['title'] ?? 'Course',
      description: c['description'] ?? '',
      instructorName: c['instructor_name'] ?? '',
      instructorPhone: '',
      thumbnailUrl: thumbUrl,
      lessonCount: c['lesson_count'] ?? 0,
      durationMinutes: c['duration_minutes'] ?? 0,
    );

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseDetailScreen(course: courseObj, index: 0),
          ),
        ).then((_) => _loadBookmarks());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.7),
                    AppColors.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: thumbUrl != null && thumbUrl.isNotEmpty
                    ? CachedNetworkImage(
                        fadeInDuration: Duration.zero,
                        imageUrl: '$apiBaseUrl/media/$thumbUrl',
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      )
                    : const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      c['category_name'] ?? 'Category',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c['title'] ?? 'Course',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        size: 12,
                        color: AppColors.textMedium,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${c['lesson_count'] ?? 0} lessons',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Remove button
            IconButton(
              icon: const Icon(
                Icons.bookmark_remove_rounded,
                color: Colors.amber,
                size: 24,
              ),
              onPressed: () => _removeCourseBookmark(c['id']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Colors.amber),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
