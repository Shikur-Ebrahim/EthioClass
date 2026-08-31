import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../config/api_config.dart';
import '../../models/course_model.dart';
import '../../models/chapter_model.dart';
import '../../services/course_service.dart';
import '../../services/payment_service.dart';
import '../../services/progress_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/session_service.dart';
import '../../services/my_learning_service.dart';
import '../auth/signup_screen.dart';
import '../auth/login_screen.dart';
import 'lesson_detail_screen.dart';
import 'payment_webview_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  final int index;
  final String categoryName;
  final bool autoPlayLast;

  const CourseDetailScreen({
    super.key,
    required this.course,
    required this.index,
    this.categoryName = 'Course',
    this.autoPlayLast = false,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  bool _isLoadingChapters = true;
  List<Chapter> _chapters = [];
  bool _isInitializingPayment = false;
  String? _prefetchedTxRef;
  String? _prefetchedCheckoutUrl;

  // Bookmark
  bool _isBookmarked = false;
  bool _bookmarkLoading = false;
  bool _isEnrolled = false;
  bool _enrollLoading = false;

  final List<Color> _headerColors = [
    const Color(0xFF0F172A),
    const Color(0xFF1E3A8A),
    const Color(0xFF166534),
    const Color(0xFF831843),
    const Color(0xFF065F46),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
    _loadChapters();
    _preInitializePayment();
    _checkBookmarkState();
    _checkEnrollmentState();
  }

    Future<void> _checkEnrollmentState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isEnrolled = prefs.getBool('enrolled_${widget.course.id}') ?? false;
      });
    }
  } catch (_) {}
  }

  Future<void> _enrollCourse() async {
    if (_enrollLoading) return;
    setState(() => _enrollLoading = true);
    
    try {
      final response = await CourseService().enrollCourse(widget.course.id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('enrolled_${widget.course.id}', true);
      
      if (mounted) {
        setState(() {
          _isEnrolled = true;
          _enrollLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Enrolled successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enrollLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to enroll')),
        );
      }
    }
  }

  Future<void> _checkBookmarkState() async {
    try {
      final data = await BookmarkService.instance.getBookmarks();
      final courses = data['courses'] as List<dynamic>? ?? [];
      if (mounted) {
        setState(() => _isBookmarked = courses.any((c) => c['id'] == widget.course.id));
      }
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    if (_bookmarkLoading) return;
    setState(() => _bookmarkLoading = true);
    final wasBookmarked = _isBookmarked;
    setState(() => _isBookmarked = !_isBookmarked); // optimistic update
    try {
      if (wasBookmarked) {
        await BookmarkService.instance.removeCourseBookmark(widget.course.id);
      } else {
        await BookmarkService.instance.addCourseBookmark(widget.course.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(!wasBookmarked ? 'ðŸ”– Course bookmarked!' : 'Bookmark removed'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: !wasBookmarked ? AppColors.primary : AppColors.grey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      // revert on failure
      if (mounted) setState(() => _isBookmarked = wasBookmarked);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update bookmark')));
    } finally {
      if (mounted) setState(() => _bookmarkLoading = false);
    }
  }


  Future<void> _loadChapters() async {
    try {
      final chapters = await CourseService().getChapters(widget.course.id);
      if (mounted) {
        setState(() {
          _chapters = chapters;
          _isLoadingChapters = false;
        });
        
        // Auto-play the last lesson if requested (e.g. from Continue Learning banner)
        if (widget.autoPlayLast) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _continueLearning();
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingChapters = false);
    }
  }

  Future<void> _preInitializePayment() async {
    try {
      _isInitializingPayment = true;
      final result = await PaymentService.initializePayment(widget.course.id);
      if (mounted) {
        setState(() {
          _prefetchedTxRef = result['tx_ref'];
          _prefetchedCheckoutUrl = result['checkout_url'];
          _isInitializingPayment = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isInitializingPayment = false);
    }
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
        : 'Complete course for Ethiopian students based on the latest curriculum.';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                SliverAppBar(
                  expandedHeight: 260,
                  pinned: true,
                  backgroundColor: headerColor,
                  leading: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.share_rounded, color: Colors.white, size: 24),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Course banner image via media proxy
                        if (widget.course.thumbnailUrl != null && widget.course.thumbnailUrl!.isNotEmpty)
                          Image.network(
                            '$apiBaseUrl/media/${widget.course.thumbnailUrl!}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [headerColor, headerColor.withBlue(headerColor.blue + 40)],
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [headerColor, headerColor.withBlue(headerColor.blue + 40)],
                              ),
                            ),
                          ),

                        // Dark gradient overlay so text is readable
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.2),
                                Colors.black.withOpacity(0.75),
                              ],
                            ),
                          ),
                        ),

                        // Text content
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 64, 24, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.course.title,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Category badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        widget.course.categoryName ?? widget.categoryName,
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                      child: Center(
                                        child: Text(
                                          widget.course.instructorName.isNotEmpty
                                              ? widget.course.instructorName.substring(0, 1).toUpperCase()
                                              : 'I',
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.course.instructorName.isNotEmpty ? widget.course.instructorName : 'Instructor',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 16),
                                    _HeaderStat(icon: Icons.play_lesson_rounded, value: '${widget.course.lessonCount}', label: 'Lessons'),
                                    const SizedBox(width: 14),
                                    _HeaderStat(
                                      icon: Icons.access_time_rounded, 
                                      value: widget.course.durationMinutes >= 60 
                                          ? '${widget.course.durationMinutes ~/ 60}h ${widget.course.durationMinutes % 60}m'
                                          : '${widget.course.durationMinutes}m', 
                                      label: 'Duration'
                                    ),
                                    const SizedBox(width: 14),
                                    _HeaderStat(
                                      icon: Icons.people_rounded, 
                                      value: widget.course.studentCount >= 1000 
                                          ? '${(widget.course.studentCount / 1000).toStringAsFixed(1)}K' 
                                          : '${widget.course.studentCount}', 
                                      label: 'Students'
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // â”€â”€ Description â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.course.description.isNotEmpty
                              ? widget.course.description
                              : 'Complete course for Ethiopian students based on the latest curriculum. Learn with high-quality video lessons and practice questions.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMedium,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // â”€â”€ Progress â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<Set<String>>(
                    valueListenable: ProgressService.instance.completedLessonsNotifier,
                    builder: (context, _, __) {
                      final progress = ProgressService.instance.calculateCourseProgress(
                        widget.course.id, 
                        widget.course.lessonCount,
                      );
                      
                      return Container(
                        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Course Progress',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                                Text('${(progress * 100).toInt()}% Complete',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress > 0 ? progress : 0.0,
                                minHeight: 8,
                                backgroundColor: AppColors.greyLight,
                                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // â”€â”€ Tabs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.grey,
                      indicatorColor: AppColors.primary,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      tabs: const [
                        Tab(text: 'Chapters'),
                        Tab(text: 'About'),
                        Tab(text: 'Instructor'),
                        Tab(text: 'Reviews'),
                      ],
                    ),
                  ),
                ),

                // â”€â”€ Tab Content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: _buildTabContent(description),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),

          // â”€â”€ Bottom bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4)),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleBookmark,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _isBookmarked ? Colors.amber.withOpacity(0.15) : AppColors.greyLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isBookmarked ? Colors.amber.withOpacity(0.5) : AppColors.greyLight,
                      ),
                    ),
                    child: _bookmarkLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(
                            _isBookmarked ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                            color: _isBookmarked ? Colors.amber : AppColors.textDark,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _isEnrolled
                      ? ElevatedButton.icon(
                          onPressed: _continueLearning,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 22),
                          label: const Text('Continue Learning',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        )
                      : ElevatedButton(
                          onPressed: _enrollCourse,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _enrollLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text('Enroll Course',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(String description) {
    switch (_currentTab) {
      case 0:
        return _buildChaptersTab();
      case 1:
        return _buildAboutTab(description);
      case 2:
        return _buildInstructorTab();
      case 3:
        return _buildReviewsTab();
      default:
        return _buildChaptersTab();
    }
  }

  Widget _buildChaptersTab() {
    if (_isLoadingChapters) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_chapters.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No chapters available yet.', style: TextStyle(color: AppColors.textMedium)),
        ),
      );
    }

    return Column(
      children: _chapters.asMap().entries.map((entry) {
        return _ChapterTile(
          chapter: entry.value,
          index: entry.key,
          onTap: () => _handleChapterTap(entry.value),
        );
      }).toList(),
    );
  }

  Widget _buildAboutTab(String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About this Course',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          Text(
            widget.course.aboutText.isNotEmpty ? widget.course.aboutText : description,
            style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.65),
          ),
          if (widget.course.aboutBullets.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'What you\'ll learn',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(height: 10),
            ...widget.course.aboutBullets.map((bullet) => Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          bullet,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructorTab() {
    final name = widget.course.instructorName.isNotEmpty ? widget.course.instructorName : 'Instructor';
    final phone = widget.course.instructorPhone.isNotEmpty ? widget.course.instructorPhone : 'N/A';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Center(
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMedium),
                    const SizedBox(width: 6),
                    Text(phone, style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('No reviews yet.', style: TextStyle(color: AppColors.grey, fontSize: 14)),
        ),
      ),
    );
  }

  Future<void> _handleChapterTap(Chapter chapter) async {
    if (!chapter.isFree) {
      final session = await SessionService.loadSession();
      if (session == null) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SignupScreen()),
          );
        }
        return;
      }
      _showUnlockDialog();
      return;
    }
    // Fetch lessons for this chapter
    try {
      final lessons = await CourseService().getLessons(chapter.id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LessonDetailScreen(
            courseId: widget.course.id,
            courseTitle: widget.course.title,
            courseThumbnailUrl: widget.course.thumbnailUrl,
            courseTotalLessons: widget.course.lessonCount,
            chapter: chapter,
            chapterTitle: chapter.title,
            isLocked: false,
            thumbnailUrl: chapter.thumbnailUrl,
            chapterNumber: chapter.chapterNumber,
            chapterDescription: chapter.description,
            lessons: lessons,
            initialLessonIndex: 0,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonDetailScreen(
                courseId: widget.course.id,
                courseTitle: widget.course.title,
                courseThumbnailUrl: widget.course.thumbnailUrl,
                courseTotalLessons: widget.course.lessonCount,
                chapter: chapter,
                chapterTitle: chapter.title,
                isLocked: false,
                thumbnailUrl: chapter.thumbnailUrl,
                chapterNumber: chapter.chapterNumber,
                chapterDescription: chapter.description,
              ),
          ),
        );
      }
    }
  }

  void _showUnlockDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.lock_open_rounded, color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 20),
              Text('Unlock ${widget.course.title}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 12),
              Text(
                'Get full access to all video lessons, notes, and quizzes for this course for just ${widget.course.price} Birr.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textMedium, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.greyLight, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handlePayment();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text('Pay ${widget.course.price} Birr',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePayment() async {
    final session = await SessionService.loadSession();
    if (session == null) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignupScreen()),
        );
      }
      return;
    }

    if (_prefetchedCheckoutUrl == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
      if (!_isInitializingPayment) {
        await _preInitializePayment();
      } else {
        while (_isInitializingPayment) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      if (mounted) Navigator.pop(context);
    }

    if (_prefetchedCheckoutUrl != null && _prefetchedTxRef != null && mounted) {
      final isSuccess = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebviewScreen(
            courseId: widget.course.id,
            checkoutUrl: _prefetchedCheckoutUrl!,
            txRef: _prefetchedTxRef!,
          ),
        ),
      );
      if (isSuccess == true) _unlockAllChapters();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to payment server.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _unlockAllChapters() {
    setState(() {
      // Optimistically unlock locally
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Course unlocked successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _continueLearning() async {
    if (_chapters.isEmpty) {
      if (_isLoadingChapters) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading chapters...'), duration: Duration(seconds: 1)),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No chapters available yet.')),
      );
      return;
    }

    // Check if user was previously watching something
    final lastWatched = ProgressService.instance.getLastWatched(widget.course.id);

    Chapter targetChapter;
    int targetLessonIndex = 0;

    if (lastWatched != null) {
      // Find the chapter they were on
      final String lastChapterId = lastWatched['chapterId'] as String;
      final int lastLessonIndex = lastWatched['lessonIndex'] as int;

      final foundChapter = _chapters.cast<Chapter?>().firstWhere(
        (c) => c?.id == lastChapterId,
        orElse: () => null,
      );

      targetChapter = foundChapter ?? _chapters.first;
      targetLessonIndex = foundChapter != null ? lastLessonIndex : 0;
    } else {
      // First time â€” start from beginning
      targetChapter = _chapters.first;
    }

    try {
      final lessons = await CourseService().getLessons(targetChapter.id);
      if (!mounted) return;

      // Clamp index in case lessons changed
      final safeIndex = targetLessonIndex < lessons.length ? targetLessonIndex : 0;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LessonDetailScreen(
            courseId: widget.course.id,
            courseTitle: widget.course.title,
            courseThumbnailUrl: widget.course.thumbnailUrl,
            courseTotalLessons: widget.course.lessonCount,
            chapter: targetChapter,
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
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonDetailScreen(
              courseId: widget.course.id,
              courseTitle: widget.course.title,
              courseThumbnailUrl: widget.course.thumbnailUrl,
              courseTotalLessons: widget.course.lessonCount,
              chapter: targetChapter,
              chapterTitle: targetChapter.title,
              isLocked: false,
              thumbnailUrl: targetChapter.thumbnailUrl,
              chapterNumber: targetChapter.chapterNumber,
              chapterDescription: targetChapter.description,
            ),
          ),
        );
      }
    }
  }
}

// â”€â”€ SharedPrefs Helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SharedPrefsHelper {
  static SharedPreferences? _instance;
  static Future<SharedPreferences> get() async {
    _instance ??= await SharedPreferences.getInstance();
    return _instance!;
  }
}

// â”€â”€ Header stat widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeaderStat({required this.icon, required this.value, required this.label});

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
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

// â”€â”€ Chapter tile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ChapterTile extends StatelessWidget {
  final Chapter chapter;
  final int index;
  final VoidCallback onTap;

  const _ChapterTile({required this.chapter, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 14, top: 0, bottom: 0, left: 0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Row(
          children: [
            // Chapter thumbnail - wide rectangle with chapter number badge
            // Chapter thumbnail - wide rectangle without overlay
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: SizedBox(
                width: 100,
                height: 72,
                child: (chapter.thumbnailUrl != null && chapter.thumbnailUrl!.isNotEmpty)
                    ? Image.network(
                        '$apiBaseUrl/media/${chapter.thumbnailUrl!}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary.withOpacity(0.7), AppColors.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFF1B5E20), AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${chapter.chapterNumber}. ${chapter.title}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    if (chapter.description != null && chapter.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(chapter.description!, style: const TextStyle(fontSize: 11, color: AppColors.textMedium), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    if (chapter.isFree) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('FREE',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success)),
      );
    }
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: AppColors.greyLight, borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.lock_rounded, color: AppColors.grey, size: 16),
    );
  }
}










