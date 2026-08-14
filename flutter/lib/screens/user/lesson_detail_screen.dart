import 'package:flutter/material.dart';
import '../../core/theme.dart';

class LessonDetailScreen extends StatefulWidget {
  final String chapterTitle;
  final bool isLocked;

  const LessonDetailScreen({
    super.key,
    required this.chapterTitle,
    this.isLocked = false,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Video Player Header ──────────────────────────────────────
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.black,
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // Video Placeholder Image / Gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.black.withOpacity(0.3),
                            Colors.black,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Top Bar (Back button, options)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  // Play Button Placeholder / Lock icon
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: widget.isLocked ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: widget.isLocked ? null : [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.isLocked ? Icons.lock_rounded : Icons.play_arrow_rounded, 
                        color: Colors.white, 
                        size: 32,
                      ),
                    ),
                  ),
                  // Title overlay
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Text(
                      widget.chapterTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tabs ─────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.grey,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              tabs: const [
                Tab(text: 'Video'),
                Tab(text: 'Notes'),
                Tab(text: 'Quiz'),
              ],
            ),
          ),

          // ── Tab Views ────────────────────────────────────────────────
          Expanded(
            child: widget.isLocked
                ? _buildLockedView()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVideoTab(),
                      _buildNotesTab(),
                      _buildQuizTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.greyLight.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, color: AppColors.grey, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chapter Locked',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Complete previous chapters or upgrade to unlock this content.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. Video Tab ─────────────────────────────────────────────────
  Widget _buildVideoTab() {
    final subtopics = [
      'Introduction and Overview',
      'Core Concepts Explained',
      'Step-by-step Example',
      'Advanced Techniques',
      'Summary and Next Steps',
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: subtopics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final isPlaying = index == 0;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPlaying ? AppColors.primary.withOpacity(0.05) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPlaying ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
            ),
            boxShadow: isPlaying ? null : [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isPlaying ? AppColors.primary : AppColors.greyLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: isPlaying ? Colors.white : AppColors.textDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtopics[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isPlaying ? FontWeight.w800 : FontWeight.w700,
                        color: isPlaying ? AppColors.primary : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${10 + index * 5} mins',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                    ),
                  ],
                ),
              ),
              if (isPlaying)
                const Icon(Icons.graphic_eq_rounded, color: AppColors.primary, size: 20),
            ],
          ),
        );
      },
    );
  }

  // ── 2. Notes Tab ─────────────────────────────────────────────────
  Widget _buildNotesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Downloadable Materials',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        _buildNoteItem('Chapter Summary', 'PDF • 2.4 MB', Icons.picture_as_pdf_rounded, const Color(0xFFE53935)),
        const SizedBox(height: 12),
        _buildNoteItem('Formula Sheet', 'PDF • 1.1 MB', Icons.picture_as_pdf_rounded, const Color(0xFFE53935)),
        const SizedBox(height: 12),
        _buildNoteItem('Presentation Slides', 'PPTX • 5.8 MB', Icons.slideshow_rounded, const Color(0xFF1E88E5)),
      ],
    );
  }

  Widget _buildNoteItem(String title, String info, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // ── 3. Quiz Tab ──────────────────────────────────────────────────
  Widget _buildQuizTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
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
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.emoji_events_rounded, color: Color(0xFF22C55E), size: 40),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chapter Quiz',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Test your knowledge on this chapter with 10 multiple-choice questions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMedium,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildQuizStat(Icons.help_outline_rounded, '10 Questions'),
                    const SizedBox(width: 24),
                    _buildQuizStat(Icons.timer_outlined, '15 Minutes'),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Start Quiz',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
