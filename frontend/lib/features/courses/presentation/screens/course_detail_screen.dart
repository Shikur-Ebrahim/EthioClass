import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/course_models.dart';
import '../../data/course_repository.dart';
import '../providers/course_provider.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  Chapter? _activeChapter;
  bool _isLoadingVideo = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo(Chapter chapter) async {
    if (chapter.videoUrl == null || chapter.videoUrl!.isEmpty) return;
    setState(() => _isLoadingVideo = true);
    await _chewieController?.dispose();
    await _videoController?.dispose();

    _videoController = VideoPlayerController.networkUrl(Uri.parse(chapter.videoUrl!));
    await _videoController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: false,
      aspectRatio: 16 / 9,
      placeholder: Container(color: Colors.black),
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.yellow,
        handleColor: AppColors.yellow,
        bufferedColor: Colors.white24,
        backgroundColor: Colors.white12,
      ),
    );
    setState(() {
      _activeChapter = chapter;
      _isLoadingVideo = false;
    });
  }

  void _onChapterTap(Chapter chapter, List<Chapter> allChapters) {
    if (chapter.isUnlocked || chapter.isFree) {
      _loadVideo(chapter);
    } else {
      _showUnlockModal(chapter);
    }
  }

  void _showUnlockModal(Chapter chapter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _UnlockModal(
        chapter: chapter,
        onUnlock: () async {
          Navigator.pop(context);
          await ref.read(courseRepositoryProvider).unlockChapter(chapter.id, paymentRef: 'TELEBIRR_${DateTime.now().millisecondsSinceEpoch}');
          ref.invalidate(chaptersProvider(widget.courseId));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chapter unlocked successfully!'), backgroundColor: AppColors.success),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));
    final chaptersAsync = ref.watch(chaptersProvider(widget.courseId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ---- TOP BAR ----
            courseAsync.when(
              loading: () => const SizedBox(height: 56),
              error: (_, __) => const SizedBox(height: 56),
              data: (course) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 15),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(course.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const Icon(Icons.more_vert, color: AppColors.textPrimary),
                  ],
                ),
              ),
            ),

            // ---- VIDEO PLAYER ----
            _buildVideoPlayer(),

            // ---- TABS ----
            Container(
              color: AppColors.cardBackground,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.yellow,
                indicatorWeight: 3,
                labelColor: AppColors.yellow,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [Tab(text: 'Syllabus'), Tab(text: 'About Course')],
              ),
            ),

            // ---- TAB CONTENT ----
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // --- SYLLABUS TAB ---
                  chaptersAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.yellow)),
                    error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: AppColors.error))),
                    data: (chapters) => ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('Chapter List', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ...chapters.map((ch) => _ChapterTile(
                          chapter: ch,
                          isActive: _activeChapter?.id == ch.id,
                          onTap: () => _onChapterTap(ch, chapters),
                        )),
                      ],
                    ),
                  ),
                  // --- ABOUT COURSE TAB ---
                  courseAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.yellow)),
                    error: (_, __) => const SizedBox(),
                    data: (course) => Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(course.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.person_outline, color: AppColors.yellow, size: 16),
                            const SizedBox(width: 6),
                            Text(course.instructorName, style: const TextStyle(color: AppColors.yellow, fontSize: 13)),
                          ]),
                          const SizedBox(height: 16),
                          Text(course.description.isEmpty ? 'No description available.' : course.description,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
                          const SizedBox(height: 16),
                          Row(children: [
                            _InfoChip(icon: Icons.video_library_outlined, label: '${course.totalChapters} Chapters'),
                            const SizedBox(width: 10),
                            _InfoChip(icon: Icons.attach_money, label: course.isFree ? 'Free' : '${course.price.toInt()} Birr'),
                          ]),
                        ],
                      ),
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

  Widget _buildVideoPlayer() {
    if (_isLoadingVideo) {
      return Container(
        height: 210,
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: AppColors.yellow)),
      );
    }

    if (_chewieController != null && _activeChapter != null) {
      return SizedBox(height: 210, child: Chewie(controller: _chewieController!));
    }

    // Placeholder when no video is selected
    return Container(
      height: 210,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1B3E), Color(0xFF081028)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_outline, color: AppColors.yellow, size: 60),
              SizedBox(height: 12),
              Text('Select a chapter to start watching', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- CHAPTER TILE ----
class _ChapterTile extends StatelessWidget {
  final Chapter chapter;
  final bool isActive;
  final VoidCallback onTap;

  const _ChapterTile({required this.chapter, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? AppColors.yellow.withOpacity(0.12) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? AppColors.yellow : AppColors.inputBorder,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Chapter number circle
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: isActive ? AppColors.yellow : AppColors.inputBackground,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${chapter.chapterNumber}',
                  style: TextStyle(
                    color: isActive ? Colors.black : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chapter.title, style: TextStyle(color: isActive ? AppColors.textPrimary : AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(chapter.durationFormatted, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            if (chapter.isFree)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Free', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 8),
            if (chapter.isCompleted)
              const Icon(Icons.check_circle, color: Colors.green, size: 20)
            else if (!chapter.isUnlocked && !chapter.isFree)
              const Icon(Icons.lock, color: AppColors.textSecondary, size: 18)
            else
              const Icon(Icons.play_circle_outline, color: AppColors.yellow, size: 20),
          ],
        ),
      ),
    );
  }
}

// ---- UNLOCK MODAL ----
class _UnlockModal extends StatelessWidget {
  final Chapter chapter;
  final VoidCallback onUnlock;

  const _UnlockModal({required this.chapter, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.inputBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          // Lock icon
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.yellow.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.lock_outline, color: AppColors.yellow, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Unlock Chapter ${chapter.chapterNumber}',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              children: [
                TextSpan(text: 'Pay ', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                TextSpan(text: '100 Birr ', style: TextStyle(color: AppColors.yellow, fontSize: 15, fontWeight: FontWeight.bold)),
                TextSpan(text: 'via ', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                TextSpan(text: 'Telebirr', style: TextStyle(color: Colors.blue, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Unlock Now button
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: onUnlock,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Unlock Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          // Cancel button
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.inputBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ---- INFO CHIP ----
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.yellow, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
