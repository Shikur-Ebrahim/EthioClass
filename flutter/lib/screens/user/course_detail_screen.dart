import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../config/api_config.dart';
import '../../models/course_model.dart';
import '../../models/chapter_model.dart';
import '../../services/course_service.dart';
import '../../services/payment_service.dart';
import 'lesson_detail_screen.dart';
import 'payment_webview_screen.dart';

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
  int _currentTab = 0;

  String? _prefetchedCheckoutUrl;
  String? _prefetchedTxRef;
  bool _isInitializingPayment = false;

  static const List<Color> _headerColors = [
    Color(0xFF1B5E20),
    Color(0xFF4527A0),
    Color(0xFFE65100),
    Color(0xFF01579B),
    Color(0xFF880E4F),
  ];

  List<Chapter> _chapters = [];
  bool _isLoadingChapters = true;

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
  }

  Future<void> _loadChapters() async {
    try {
      final chapters = await CourseService().getChapters(widget.course.id);
      if (mounted) {
        setState(() {
          _chapters = chapters;
          _isLoadingChapters = false;
        });
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
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                  ),
                  title: const Text(
                    'Course Details',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
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
                      child: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
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
                                // Category badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Grade 12',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
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
                                    _HeaderStat(icon: Icons.play_lesson_rounded, value: '36', label: 'Lessons'),
                                    const SizedBox(width: 14),
                                    _HeaderStat(icon: Icons.access_time_rounded, value: '18h 45m', label: 'Duration'),
                                    const SizedBox(width: 14),
                                    _HeaderStat(icon: Icons.people_rounded, value: '12.4K', label: 'Students'),
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

                // ── Description ──────────────────────────────────────
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

                // ── Progress ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
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
                            const Text('66% Complete',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: const LinearProgressIndicator(
                            value: 0.66,
                            minHeight: 8,
                            backgroundColor: AppColors.greyLight,
                            valueColor: AlwaysStoppedAnimation(AppColors.primary),
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

                // ── Tab Content ───────────────────────────────────────
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

          // ── Bottom bar ───────────────────────────────────────────
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
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.greyLight),
                  ),
                  child: const Icon(Icons.favorite_border_rounded, color: AppColors.textDark),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
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

  void _handleChapterTap(Chapter chapter) {
    if (!chapter.isFree) {
      _showUnlockDialog();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LessonDetailScreen(chapterTitle: chapter.title, isLocked: false),
        ),
      );
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
              const Text(
                'Get full access to all video lessons, notes, and quizzes for this course for just 249 Birr.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textMedium, height: 1.5),
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
                      child: const Text('Pay 249 Birr',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
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
      // Assuming a reload from backend would happen eventually
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Course unlocked successfully! 🎉'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Header stat widget ────────────────────────────────────────
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

// ── Chapter tile ──────────────────────────────────────────────
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.greyLight, borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text('${chapter.chapterNumber}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chapter.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  if (chapter.description != null && chapter.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(chapter.description!, style: const TextStyle(fontSize: 11, color: AppColors.textMedium), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
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


