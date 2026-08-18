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
  List<DownloadedLesson> _downloadedLessons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    final lessons = await DownloadService.instance.getDownloadedLessons();
    setState(() {
      _downloadedLessons = lessons;
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
          : _downloadedLessons.isEmpty
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
                            'Downloaded Lessons',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._downloadedLessons.map((d) => _buildLessonItem(d)),
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
    int totalBytes = _downloadedLessons.fold(0, (sum, d) => sum + d.sizeBytes);
    
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
                Text('${_downloadedLessons.length} Lessons downloaded', style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                const SizedBox(height: 2),
                Text('Total size: ${_formatBytes(totalBytes)}', style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonItem(DownloadedLesson dl) {
    final lesson = dl.lesson;
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonDetailScreen(
              chapterTitle: dl.courseTitle,
              lessons: [lesson], // Just pass this single downloaded lesson for offline viewing
              initialLessonIndex: 0,
            ),
          ),
        );
        // Refresh when coming back in case they deleted it
        _loadDownloads();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
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
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${lesson.durationMinutes} min', style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                      const Text('  •  ', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
                      Text(_formatBytes(dl.sizeBytes), style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(dl.courseTitle, style: const TextStyle(fontSize: 10, color: AppColors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () async {
                // Delete confirmation
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
                          await DownloadService.instance.deleteLesson(lesson.id);
                          _loadDownloads();
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

