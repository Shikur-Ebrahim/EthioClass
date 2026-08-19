import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../config/api_config.dart';
import '../../services/download_service.dart';
import '../../models/downloaded_lesson_model.dart';
import '../../models/lesson_model.dart';
import 'lesson_detail_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  Map<String, List<DownloadedLesson>> _groupedDownloads = {};
  final Set<String> _expandedCourses = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    final lessons = await DownloadService.instance.getDownloadedLessons();

    final validLessons = <DownloadedLesson>[];
    for (final dl in lessons) {
      if (dl.courseTitle == dl.chapterTitle || dl.courseTitle == 'Course') {
        await DownloadService.instance.deleteLesson(dl.lesson.id);
      } else {
        validLessons.add(dl);
      }
    }

    Map<String, List<DownloadedLesson>> grouped = {};
    for (var dl in validLessons) {
      final course = dl.courseTitle;
      if (!grouped.containsKey(course)) grouped[course] = [];
      grouped[course]!.add(dl);
    }

    setState(() {
      _groupedDownloads = grouped;
      _isLoading = false;
      // If only one course downloaded, auto-expand it
      // If multiple courses, keep all collapsed so user can tap to open
      if (grouped.length == 1) {
        _expandedCourses.add(grouped.keys.first);
      }
    });
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Downloads',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textDark),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _groupedDownloads.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadDownloads,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _groupedDownloads.length,
                    itemBuilder: (context, index) {
                      final courseTitle = _groupedDownloads.keys.elementAt(index);
                      final lessons = _groupedDownloads[courseTitle]!;
                      final isExpanded = _expandedCourses.contains(courseTitle);
                      return _buildCourseAccordion(courseTitle, lessons, isExpanded);
                    },
                  ),
                ),
    );
  }

  Widget _buildCourseAccordion(String courseTitle, List<DownloadedLesson> lessons, bool isExpanded) {
    final courseSize = lessons.fold(0, (sum, l) => sum + l.sizeBytes);
    final totalDuration = lessons.fold(0, (sum, l) => sum + l.lesson.durationMinutes);
    final thumbUrl = lessons.first.courseThumbnailUrl;

    int totalCourseLessons = lessons.first.courseTotalLessons;
    if (totalCourseLessons <= 0) totalCourseLessons = 1;
    double progress = lessons.length / totalCourseLessons;
    if (progress > 1.0) progress = 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // ── Course Header Row (tappable) ──
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedCourses.remove(courseTitle);
                  } else {
                    _expandedCourses.add(courseTitle);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.only(right: 14, top: 0, bottom: 0, left: 0),
                decoration: const BoxDecoration(
                  // Subtle blue-gray tint to distinguish from white lesson cards
                  color: Color(0xFFEBF0FB),
                ),
                child: Row(
                  children: [
                    // Thumbnail — same style as home page course cards
                    Container(
                      width: 72, height: 72,
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(0),
                          bottomLeft: Radius.circular(0),
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: thumbUrl != null && thumbUrl.isNotEmpty
                          ? Image.network(
                              '$apiBaseUrl/media/$thumbUrl',
                              width: 72, height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _defaultCourseIcon(),
                            )
                          : _defaultCourseIcon(),
                    ),
                    const SizedBox(width: 14),
                    // Title + subtitle + spacing
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              courseTitle,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${lessons.length} Lessons • ${_formatDuration(totalDuration)} • ${_formatBytes(courseSize)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Progress ring + chevron
                    Column(
                      children: [
                        SizedBox(
                          width: 44, height: 44,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 4,
                                color: AppColors.primary,
                                backgroundColor: AppColors.primary.withOpacity(0.12),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMedium, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Expandable Lessons ──
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 280),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFE8E8E8)),
                  ...lessons.asMap().entries.map((e) {
                    final allCourseLessons = lessons.map((l) => l.lesson).toList();
                    return _buildLessonCard(e.value, e.key + 1, allCourseLessons, e.key);
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultCourseIcon() {
    return Container(
      width: 72, height: 72,
      color: AppColors.primary.withOpacity(0.1),
      child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 28),
    );
  }

  Widget _buildLessonCard(DownloadedLesson dl, int displayIndex, List<Lesson> allCourseLessons, int tapIndex) {
    final lesson = dl.lesson;
    final thumbUrl = lesson.thumbnailUrl ?? dl.courseThumbnailUrl;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonDetailScreen(
              lessons: allCourseLessons,
              chapterTitle: dl.chapterTitle,
              chapterDescription: '',
              courseTitle: dl.courseTitle,
              courseThumbnailUrl: dl.courseThumbnailUrl,
              thumbnailUrl: dl.courseThumbnailUrl,
              initialLessonIndex: tapIndex,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        ),
        child: Row(
          children: [
            // Thumbnail with duration badge
            Container(
              width: 100, height: 64,
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
                        ? Image.network(
                            '$apiBaseUrl/media/$thumbUrl',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.ondemand_video_rounded, color: AppColors.grey)),
                          )
                        : const Center(child: Icon(Icons.ondemand_video_rounded, color: AppColors.grey)),
                  ),
                  Positioned(
                    bottom: 4, right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${lesson.durationMinutes}:00',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Title & size
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$displayIndex. ${lesson.title}',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${lesson.durationMinutes}:00 • ${_formatBytes(dl.sizeBytes)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
            // Green check + 3-dots
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Color(0xFF22C55E), size: 14),
                ),
                const SizedBox(width: 2),
                GestureDetector(
                  onTap: () => _showDeleteOptions(dl),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.more_vert, color: AppColors.textMedium, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLessonOptions(BuildContext context, DownloadedLesson dl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            
            if (dl.lesson.notesUrl != null && dl.lesson.notesUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                title: const Text('View Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(bottomSheetContext); // close bottom sheet
                  // Navigate to LessonDetailScreen directly on the Notes tab
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LessonDetailScreen(
                        lessons: [dl.lesson],
                        chapterTitle: dl.chapterTitle,
                        chapterDescription: '',
                        courseTitle: dl.courseTitle,
                        courseThumbnailUrl: dl.courseThumbnailUrl,
                        thumbnailUrl: dl.courseThumbnailUrl,
                        initialLessonIndex: 0,
                        initialTab: 1, // 1 is Notes tab
                      ),
                    ),
                  );
                },
              ),
              
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Download', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _deleteDownload(dl.lesson.id);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDownload(String lessonId) async {
    await DownloadService.instance.deleteLesson(lessonId);
    _loadDownloads();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_done_rounded, size: 80, color: AppColors.primary.withOpacity(0.4)),
          const SizedBox(height: 20),
          const Text('No downloads yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 8),
          const Text('Videos you download will appear here', style: TextStyle(fontSize: 14, color: AppColors.textMedium)),
        ],
      ),
    );
  }
}
