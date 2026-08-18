import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/download_service.dart';
import '../../models/downloaded_lesson_model.dart';
import 'lesson_detail_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  // courseTitle -> chapterTitle -> List<DownloadedLesson>
  Map<String, Map<String, List<DownloadedLesson>>> _groupedDownloads = {};
  int _totalBytes = 0;
  int _totalLessons = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    final lessons = await DownloadService.instance.getDownloadedLessons();
    
    Map<String, Map<String, List<DownloadedLesson>>> grouped = {};
    int totalB = 0;
    
    for (var dl in lessons) {
      totalB += dl.sizeBytes;
      
      final course = dl.courseTitle;
      final chapter = dl.chapterTitle;
      
      if (!grouped.containsKey(course)) {
        grouped[course] = {};
      }
      if (!grouped[course]!.containsKey(chapter)) {
        grouped[course]![chapter] = [];
      }
      grouped[course]![chapter]!.add(dl);
    }
    
    setState(() {
      _groupedDownloads = grouped;
      _totalBytes = totalB;
      _totalLessons = lessons.length;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Downloads',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _groupedDownloads.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadDownloads,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildHeaderStats(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Downloaded Courses',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._groupedDownloads.entries.map((courseEntry) => _buildCourseItem(courseEntry.key, courseEntry.value)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_for_offline_rounded, size: 80, color: AppColors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No Downloads Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 8),
          const Text('Download lessons to watch them offline', style: TextStyle(fontSize: 14, color: AppColors.textMedium)),
        ],
      ),
    );
  }

  Widget _buildHeaderStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.folder_special_rounded, color: AppColors.primary, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offline Storage',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Text('$_totalLessons Lessons downloaded', style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                const SizedBox(height: 2),
                Text('Total size: ${_formatBytes(_totalBytes)}', style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(String courseTitle, Map<String, List<DownloadedLesson>> chapters) {
    int courseSize = 0;
    int lessonCount = 0;
    for (var lessons in chapters.values) {
      lessonCount += lessons.length;
      for (var l in lessons) {
        courseSize += l.sizeBytes;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.school_rounded, color: AppColors.primary),
        ),
        title: Text(courseTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        subtitle: Text('$lessonCount Lessons  •  ${_formatBytes(courseSize)}', style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
        children: chapters.entries.map((chapterEntry) => _buildChapterItem(chapterEntry.key, chapterEntry.value)).toList(),
      ),
    );
  }

  Widget _buildChapterItem(String chapterTitle, List<DownloadedLesson> lessons) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.only(left: 32, right: 16),
        leading: const Icon(Icons.menu_book_rounded, color: AppColors.textMedium, size: 20),
        title: Text(chapterTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        subtitle: Text('${lessons.length} Lessons', style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
        children: lessons.map((dl) => _buildLessonItem(dl)).toList(),
      ),
    );
  }

  Widget _buildLessonItem(DownloadedLesson dl) {
    final lesson = dl.lesson;
    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.greyLight, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LessonDetailScreen(
                      courseTitle: dl.courseTitle,
                      chapterTitle: dl.chapterTitle,
                      lessons: [lesson],
                      initialLessonIndex: 0,
                    ),
                  ),
                );
                _loadDownloads();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${lesson.durationMinutes} min  •  ${_formatBytes(dl.sizeBytes)}', style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _deleteDownload(lesson.id),
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDownload(String id) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Download'),
        content: const Text('Are you sure you want to remove this lesson from your device?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DownloadService.instance.deleteLesson(id);
              _loadDownloads();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

