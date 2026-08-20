import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../config/api_config.dart';
import '../../services/download_service.dart';
import '../../models/downloaded_lesson_model.dart';
import '../../models/lesson_model.dart';
import '../../services/progress_service.dart';
import 'lesson_detail_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  Map<String, List<DownloadedLesson>> _groupedDownloads = {};
  Map<String, List<DownloadedLesson>> _filtered = {};
  final Set<String> _expandedCourses = {};
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  Map<String, dynamic>? _lastDownloadedLesson;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    await ProgressService.instance.init();
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
    // Load last opened downloaded lesson
    final lastDl = ProgressService.instance.getLastDownloadedLesson();
    // Only show banner if the lesson still exists in downloads
    Map<String, dynamic>? validLastDl;
    if (lastDl != null) {
      final allLessons = validLessons;
      final found = allLessons.any((dl) => dl.lesson.id == lastDl['lessonId']);
      if (found) validLastDl = lastDl;
    }
    setState(() {
      _groupedDownloads = grouped;
      _filtered = grouped;
      _lastDownloadedLesson = validLastDl;
      _isLoading = false;
      if (grouped.length == 1) _expandedCourses.add(grouped.keys.first);
    });
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filtered = _groupedDownloads;
      } else {
        _filtered = {};
        for (final entry in _groupedDownloads.entries) {
          if (entry.key.toLowerCase().contains(query.toLowerCase())) {
            _filtered[entry.key] = entry.value;
          }
        }
      }
    });
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) { d /= 1024; i++; }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  int get _totalLessons => _groupedDownloads.values.fold(0, (s, l) => s + l.length);
  int get _totalBytes => _groupedDownloads.values.expand((l) => l).fold(0, (s, dl) => s + dl.sizeBytes);
  int get _totalMinutes => _groupedDownloads.values.expand((l) => l).fold(0, (s, dl) => s + dl.lesson.durationMinutes);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [_buildSliverHeader()],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _groupedDownloads.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadDownloads,
                    color: AppColors.primary,
                    child: _filtered.isEmpty
                        ? _buildNoResults()
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            itemCount: _filtered.length + (_lastDownloadedLesson != null ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Show continue learning banner as first item
                              if (_lastDownloadedLesson != null && index == 0) {
                                return _buildContinueLearningBanner();
                              }
                              final adjustedIndex = _lastDownloadedLesson != null ? index - 1 : index;
                              final courseTitle = _filtered.keys.elementAt(adjustedIndex);
                              final lessons = _filtered[courseTitle]!;
                              final isExpanded = _expandedCourses.contains(courseTitle);
                              return _buildCourseCard(courseTitle, lessons, isExpanded);
                            },
                          ),
                  ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3E1C00), Color(0xFF6B3A2A)],
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
                          Text('Downloads', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                          SizedBox(height: 2),
                          Text('Your offline library', style: TextStyle(fontSize: 13, color: Colors.white54)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storage_rounded, color: AppColors.primary, size: 16),
                          const SizedBox(width: 6),
                          Text(_formatBytes(_totalBytes),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!_isLoading && _groupedDownloads.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Row(
                    children: [
                      _buildStatChip(Icons.folder_outlined, '${_groupedDownloads.length}', 'Courses'),
                      const SizedBox(width: 10),
                      _buildStatChip(Icons.play_circle_outline_rounded, '$_totalLessons', 'Lessons'),
                      const SizedBox(width: 10),
                      _buildStatChip(Icons.timer_outlined, _formatDuration(_totalMinutes), 'Duration'),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
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
                      hintText: 'Search downloaded courses...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.6), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.6), size: 18),
                              onPressed: () { _searchCtrl.clear(); _applySearch(''); },
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

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(String courseTitle, List<DownloadedLesson> lessons, bool isExpanded) {
    final courseSize = lessons.fold(0, (sum, l) => sum + l.sizeBytes);
    final totalDuration = lessons.fold(0, (sum, l) => sum + l.lesson.durationMinutes);
    final thumbUrl = lessons.first.courseThumbnailUrl;
    int totalCourseLessons = lessons.first.courseTotalLessons;
    if (totalCourseLessons <= 0) totalCourseLessons = 1;
    double progress = lessons.length / totalCourseLessons;
    if (progress > 1.0) progress = 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) { _expandedCourses.remove(courseTitle); }
                  else { _expandedCourses.add(courseTitle); }
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90, height: 80,
                      child: thumbUrl != null && thumbUrl.isNotEmpty
                          ? Image.network('$apiBaseUrl/media/$thumbUrl', fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _defaultCourseIcon())
                          : _defaultCourseIcon(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(courseTitle,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.play_circle_outline, size: 12, color: AppColors.textMedium),
                                const SizedBox(width: 4),
                                Text('${lessons.length} lessons', style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                                const SizedBox(width: 10),
                                const Icon(Icons.timer_outlined, size: 12, color: AppColors.textMedium),
                                const SizedBox(width: 4),
                                Text(_formatDuration(totalDuration), style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress, minHeight: 5,
                                backgroundColor: AppColors.primary.withOpacity(0.12),
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('${(progress * 100).toInt()}% downloaded  •  ${_formatBytes(courseSize)}',
                                style: const TextStyle(fontSize: 10, color: AppColors.textMedium)),
                          ],
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMedium, size: 22),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 280),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 4),
                  ...lessons.asMap().entries.map((e) {
                    final allCourseLessons = lessons.map((l) => l.lesson).toList();
                    return _buildLessonTile(e.value, e.key + 1, allCourseLessons, e.key);
                  }),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Continue Learning Banner ──────────────────────────────────────

  Widget _buildContinueLearningBanner() {
    final dl = _lastDownloadedLesson!;
    final thumbUrl = dl['thumbUrl'] as String;
    final lessonTitle = dl['lessonTitle'] as String;
    final courseTitle = dl['courseTitle'] as String;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A7A4A), Color(0xFF22C55E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _openLastDownloadedLesson,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 62, height: 62,
                    color: Colors.white.withOpacity(0.15),
                    child: thumbUrl.isNotEmpty
                        ? Image.network('$apiBaseUrl/media/$thumbUrl', fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.play_circle_filled, color: Colors.white, size: 32))
                        : const Icon(Icons.play_circle_filled, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(width: 14),
                // Text info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Continue Watching', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.5)),
                      const SizedBox(height: 3),
                      Text(lessonTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(courseTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Resume button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: Color(0xFF16A34A), size: 16),
                      SizedBox(width: 4),
                      Text('Resume', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openLastDownloadedLesson() {
    final dl = _lastDownloadedLesson;
    if (dl == null) return;
    final courseTitle = dl['courseTitle'] as String;
    final chapterTitle = dl['chapterTitle'] as String;
    final lessonIndex = dl['lessonIndex'] as int;
    final thumbUrl = dl['thumbUrl'] as String;

    // Find lessons from grouped downloads
    final courseLessons = _groupedDownloads[courseTitle];
    if (courseLessons == null || courseLessons.isEmpty) return;

    final allLessons = courseLessons.map((d) => d.lesson).toList();
    final safeIndex = lessonIndex < allLessons.length ? lessonIndex : 0;

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => LessonDetailScreen(
        lessons: allLessons,
        chapterTitle: chapterTitle,
        chapterDescription: '',
        courseTitle: courseTitle,
        courseThumbnailUrl: thumbUrl,
        thumbnailUrl: thumbUrl,
        initialLessonIndex: safeIndex,
      ),
    ));
  }

  Widget _defaultCourseIcon() {
    return Container(
      width: 90, height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.7), AppColors.primary],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.school_rounded, color: Colors.white, size: 30),
    );
  }

  Widget _buildLessonTile(DownloadedLesson dl, int displayIndex, List<Lesson> allCourseLessons, int tapIndex) {
    final lesson = dl.lesson;
    final thumbUrl = lesson.thumbnailUrl ?? dl.courseThumbnailUrl;

    return InkWell(
      onTap: () async {
        // Save this as the last downloaded lesson for "Continue Learning"
        await ProgressService.instance.saveLastDownloadedLesson(
          courseTitle: dl.courseTitle,
          chapterTitle: dl.chapterTitle,
          lessonId: lesson.id,
          lessonTitle: lesson.title,
          lessonIndex: tapIndex,
          courseThumbnailUrl: dl.courseThumbnailUrl ?? '',
        );
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => LessonDetailScreen(
            lessons: allCourseLessons,
            chapterTitle: dl.chapterTitle,
            chapterDescription: '',
            courseTitle: dl.courseTitle,
            courseThumbnailUrl: dl.courseThumbnailUrl,
            thumbnailUrl: dl.courseThumbnailUrl,
            initialLessonIndex: tapIndex,
          ),
        ));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 88, height: 60,
              decoration: BoxDecoration(color: const Color(0xFFE8E8E8), borderRadius: BorderRadius.circular(10)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: thumbUrl != null && thumbUrl.isNotEmpty
                        ? Image.network('$apiBaseUrl/media/$thumbUrl', fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.ondemand_video_rounded, color: AppColors.grey)))
                        : const Center(child: Icon(Icons.ondemand_video_rounded, color: AppColors.grey)),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  Positioned(
                    bottom: 4, right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.72), borderRadius: BorderRadius.circular(4)),
                      child: Text('${lesson.durationMinutes}m',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$displayIndex. ${lesson.title}',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.download_done_rounded, size: 10, color: Color(0xFF16A34A)),
                            SizedBox(width: 3),
                            Text('Offline', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_formatBytes(dl.sizeBytes), style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showLessonOptions(context, dl),
              child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.more_vert, color: AppColors.textMedium, size: 20)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLessonOptions(BuildContext context, DownloadedLesson dl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bsc) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(dl.lesson.title, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 4),
              if (dl.lesson.notesUrl != null && dl.lesson.notesUrl!.isNotEmpty)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
                  ),
                  title: const Text('View Notes', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Open PDF notes for this lesson', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(bsc);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => LessonDetailScreen(
                      lessons: [dl.lesson], chapterTitle: dl.chapterTitle, chapterDescription: '',
                      courseTitle: dl.courseTitle, courseThumbnailUrl: dl.courseThumbnailUrl,
                      thumbnailUrl: dl.courseThumbnailUrl, initialLessonIndex: 0, initialTab: 1,
                    )));
                  },
                ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.quiz_outlined, color: Colors.orange, size: 20),
                ),
                title: const Text('Take Quiz', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Test your knowledge', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(bsc);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => LessonDetailScreen(
                    lessons: [dl.lesson], chapterTitle: dl.chapterTitle, chapterDescription: '',
                    courseTitle: dl.courseTitle, courseThumbnailUrl: dl.courseThumbnailUrl,
                    thumbnailUrl: dl.courseThumbnailUrl, initialLessonIndex: 0, initialTab: 2,
                  )));
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                ),
                title: const Text('Delete Download', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                subtitle: const Text('Remove from offline storage', style: TextStyle(fontSize: 11)),
                onTap: () { Navigator.pop(bsc); _deleteDownload(dl.lesson.id); },
              ),
              const SizedBox(height: 16),
            ],
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.download_for_offline_outlined, size: 56, color: AppColors.primary.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            const Text('No Downloads Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 10),
            const Text('Download lessons from any course to\nwatch them offline anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textMedium, height: 1.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: AppColors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No results found', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text('No downloads match "$_searchQuery"', style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
        ],
      ),
    );
  }
}
