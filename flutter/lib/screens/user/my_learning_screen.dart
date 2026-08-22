import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../config/api_config.dart';
import '../../services/my_learning_service.dart';
import 'course_detail_screen.dart';
import '../../services/course_service.dart';

class MyLearningScreen extends StatefulWidget {
  const MyLearningScreen({super.key});

  @override
  State<MyLearningScreen> createState() => _MyLearningScreenState();
}

class _MyLearningScreenState extends State<MyLearningScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<MyLearningCourse> _inProgress = [];
  List<MyLearningCourse> _completed = [];
  List<MyLearningCourse> _saved = [];

  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await MyLearningService.instance.getMyLearning();
      final enrolled = data['enrolled'] ?? [];
      if (mounted) {
        setState(() {
          _inProgress = enrolled.where((c) => !c.isCompleted).toList();
          _completed = enrolled.where((c) => c.isCompleted).toList();
          _saved = data['saved'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final err = e.toString().toLowerCase();
        setState(() {
          _isLoading = false;
          _error = (err.contains('socketexception') || err.contains('failed host lookup'))
              ? 'No internet connection.'
              : 'Failed to load your courses.';
        });
      }
    }
  }

  String _formatLastAccessed(String? iso) {
    if (iso == null) return 'Not started';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return 'Just now';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return 'Recently';
    }
  }

  List<MyLearningCourse> _filtered(List<MyLearningCourse> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((c) =>
        c.title.toLowerCase().contains(q) ||
        c.instructorName.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Learning',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search your courses...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.6)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.white.withOpacity(0.5),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'In Progress (${_inProgress.length})'),
                  Tab(text: 'Completed (${_completed.length})'),
                  Tab(text: 'Saved (${_saved.length})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_filtered(_inProgress), 'in_progress'),
                    _buildList(_filtered(_completed), 'completed'),
                    _buildList(_filtered(_saved), 'saved'),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMedium, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<MyLearningCourse> courses, String type) {
    if (courses.isEmpty) {
      String msg;
      IconData icon;
      switch (type) {
        case 'in_progress':
          msg = 'No courses in progress.\nStart learning by unlocking a course!';
          icon = Icons.play_circle_outline_rounded;
          break;
        case 'completed':
          msg = 'No completed courses yet.\nKeep going, you\'re doing great!';
          icon = Icons.emoji_events_outlined;
          break;
        default:
          msg = 'No saved courses.\nBookmark a course to save it here!';
          icon = Icons.bookmark_border_rounded;
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: AppColors.greyLight),
              const SizedBox(height: 16),
              Text(msg, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMedium, fontSize: 15, height: 1.5)),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: courses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) => _buildCard(courses[i], type),
      ),
    );
  }

  Widget _buildCard(MyLearningCourse course, String type) {
    final pct = (course.progress * 100).toInt();
    final badgeText = type == 'completed' ? 'Completed' : type == 'saved' ? 'Saved' : 'In Progress';
    final badgeColor = type == 'completed'
        ? const Color(0xFF27AE60)
        : type == 'saved'
            ? const Color(0xFF9B51E0)
            : const Color(0xFF2D9CDB);

    return GestureDetector(
      onTap: () async {
        final courses = await CourseService().getCourses();
        final match = courses.where((c) => c.id == course.id).toList();
        if (match.isNotEmpty && mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => CourseDetailScreen(course: match.first, index: 0),
          ));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Thumbnail + info row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            '$apiBaseUrl/media/${course.thumbnailUrl}',
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderIcon(),
                          )
                        : _placeholderIcon(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                course.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                    height: 1.3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                course.instructorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.menu_book_outlined, size: 14, color: AppColors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${course.completedLessons}/${course.totalLessons} lessons',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: course.progress,
                        minHeight: 8,
                        backgroundColor: AppColors.greyLight,
                        color: type == 'completed'
                            ? const Color(0xFF27AE60)
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$pct%',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.greyLight),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Last accessed: ${_formatLastAccessed(course.lastAccessedAt)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 36),
    );
  }
}
