import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../config/api_config.dart';
import '../../services/download_service.dart';
import '../../models/downloaded_lesson_model.dart';
import 'lesson_detail_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  // courseTitle -> List<DownloadedLesson>
  Map<String, List<DownloadedLesson>> _groupedDownloads = {};
  int _totalBytes = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    final lessons = await DownloadService.instance.getDownloadedLessons();

    // Auto-clear old corrupted downloads where courseTitle == chapterTitle (old broken format)
    final validLessons = <DownloadedLesson>[];
    for (final dl in lessons) {
      if (dl.courseTitle == dl.chapterTitle || dl.courseTitle == 'Course') {
        // Old corrupted data — delete it silently
        await DownloadService.instance.deleteLesson(dl.lesson.id);
      } else {
        validLessons.add(dl);
      }
    }

    Map<String, List<DownloadedLesson>> grouped = {};
    int totalB = 0;

    for (var dl in validLessons) {
      totalB += dl.sizeBytes;
      final course = dl.courseTitle;
      if (!grouped.containsKey(course)) grouped[course] = [];
      grouped[course]!.add(dl);
    }

    setState(() {
      _groupedDownloads = grouped;
      _totalBytes = totalB;
      _isLoading = false;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
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
    int h = minutes ~/ 60;
    int m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Downloads',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
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
                    padding: const EdgeInsets.only(top: 8, bottom: 40),
                    itemCount: _groupedDownloads.length,
                    itemBuilder: (context, index) {
                      final courseTitle = _groupedDownloads.keys.elementAt(index);
                      final lessons = _groupedDownloads[courseTitle]!;
                      return _buildCourseSection(courseTitle, lessons);
                    },
                  ),
                ),
    );
  }

  Widget _buildCourseSection(String courseTitle, List<DownloadedLesson> lessons) {
    int courseSize = lessons.fold(0, (sum, l) => sum + l.sizeBytes);
    int totalCourseDuration = lessons.fold(0, (sum, l) => sum + l.lesson.durationMinutes);
    String? thumbUrl = lessons.first.courseThumbnailUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              // Course Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: thumbUrl != null && thumbUrl.isNotEmpty
                    ? Image.network(
                        '$apiBaseUrl/media/$thumbUrl',
                        width: 110, height: 70, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultCourseIcon(),
                      )
                    : _defaultCourseIcon(),
              ),
              const SizedBox(width: 16),
              Expanded(
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
                      '${lessons.length} Lessons • ${_formatDuration(totalCourseDuration)}', 
                      style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                    ),
                  ],
                ),
              ),
              // Circular progress (100% since it's downloaded)
              SizedBox(
                width: 48, height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 4,
                      color: AppColors.primary,
                    ),
                    const Text('100%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // "Downloaded Lessons" Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Downloaded Lessons', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  Text('${_formatBytes(courseSize)} Used', style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 3, width: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: AppColors.greyLight),
            ],
          ),
        ),

        // List of Lessons
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lessons.length,
          itemBuilder: (context, index) {
            return _buildLessonCard(lessons[index], index + 1);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _defaultCourseIcon() {
    return Container(
      width: 110, height: 70,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
      ),
      child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 28),
    );
  }

  Widget _buildLessonCard(DownloadedLesson dl, int index) {
    final lesson = dl.lesson;
    final thumbUrl = lesson.thumbnailUrl ?? dl.courseThumbnailUrl;

    return InkWell(
      onTap: () {
        // We do not push to LessonDetailScreen directly from here without Chapter structure,
        // but we can still push to LessonDetailScreen with this single lesson if needed.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonDetailScreen(
              lessons: [lesson], // Just playing this single lesson
              chapterTitle: dl.chapterTitle,
              chapterDescription: '',
              courseTitle: dl.courseTitle,
              thumbnailUrl: dl.courseThumbnailUrl,
              initialLessonIndex: 0,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 110,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
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
                  // Duration Badge
                  Positioned(
                    bottom: 4, right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
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
            const SizedBox(width: 14),
            
            // Title & Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$index. ${lesson.title}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${lesson.durationMinutes}:00 • ${_formatBytes(dl.sizeBytes)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
            
            // Right Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Color(0xFF22C55E), size: 14),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showDeleteOptions(dl),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
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

  void _showDeleteOptions(DownloadedLesson dl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Download', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteDownload(dl.lesson.id);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
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
          Icon(Icons.download_done_rounded, size: 80, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: 20),
          const Text(
            'No downloads yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Videos you download will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}
