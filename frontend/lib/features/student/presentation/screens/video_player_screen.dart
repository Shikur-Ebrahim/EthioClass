import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'course_details_screen.dart'; // reuse CourseColors

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final String courseTitle;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    this.videoTitle = '1. Physical Quantities and Units',
    this.courseTitle = 'Physics – Grade 12',
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  int _activeTab = 1; // default to "About Course"
  bool _isLoading = true;
  bool _hasError = false;

  final _tabs = ['Syllabus', 'About Course', 'Resources'];

  @override
  void initState() {
    super.initState();
    // Lock to landscape-capable orientations for better video UX
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: 16 / 9,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: CourseColors.yellow,
          handleColor: CourseColors.yellow,
          backgroundColor: CourseColors.border,
          bufferedColor: CourseColors.primaryBlue.withOpacity(0.4),
        ),
        placeholder: Container(color: const Color(0xFF0A1628)),
        errorBuilder: (ctx, errorMsg) => _buildErrorWidget(),
      );
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CourseColors.bg,
      appBar: AppBar(
        backgroundColor: CourseColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: CourseColors.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Video Player',
            style: TextStyle(color: CourseColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.subtitles_outlined, color: CourseColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Video Player
          _buildVideoPlayer(),
          // ── Tabs
          _buildTabBar(),
          // ── Tab content
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  // ── VIDEO PLAYER ─────────────────────────────────────────────
  Widget _buildVideoPlayer() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0A1628),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: CourseColors.yellow))
            : _hasError || _chewieController == null
                ? _buildErrorWidget()
                : Chewie(controller: _chewieController!),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: const Color(0xFF0A1628),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: CourseColors.textSecondary, size: 48),
            SizedBox(height: 12),
            Text('Unable to load video.\nPlease check your connection.',
                textAlign: TextAlign.center,
                style: TextStyle(color: CourseColors.textSecondary, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }

  // ── TAB BAR ──────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Column(
      children: [
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(_tabs.length, (i) {
              final active = i == _activeTab;
              return GestureDetector(
                onTap: () => setState(() => _activeTab = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 24),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: active ? CourseColors.yellow : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    _tabs[i],
                    style: TextStyle(
                      color: active ? CourseColors.yellow : CourseColors.textSecondary,
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const Divider(color: CourseColors.border, height: 1),
      ],
    );
  }

  // ── TAB CONTENT ──────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_activeTab) {
      case 0:
        return const _SyllabusTab();
      case 1:
        return const _AboutCourseTab();
      case 2:
        return const _ResourcesTab();
      default:
        return const _AboutCourseTab();
    }
  }
}

// ─────────────────────────────────────────────────────────────
// TAB: SYLLABUS
// ─────────────────────────────────────────────────────────────
class _SyllabusTab extends StatelessWidget {
  const _SyllabusTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _SyllabusItem(index: 1, title: 'Physical Quantities and Units', duration: '12:45', isActive: true, isCompleted: false),
        _SyllabusItem(index: 2, title: 'Measurement and Units', duration: '15:20', isCompleted: true),
        _SyllabusItem(index: 3, title: 'Scalars and Vectors', duration: '18:10', isCompleted: true),
        _SyllabusItem(index: 4, title: 'Vector Addition', duration: '20:00', isLocked: true),
        _SyllabusItem(index: 5, title: 'Kinematics in One Dimension', duration: '18:30', isLocked: true),
        _SyllabusItem(index: 6, title: 'Projectile Motion', duration: '22:10', isLocked: true),
      ],
    );
  }
}

class _SyllabusItem extends StatelessWidget {
  final int index;
  final String title, duration;
  final bool isActive, isCompleted, isLocked;

  const _SyllabusItem({
    required this.index, required this.title, required this.duration,
    this.isActive = false, this.isCompleted = false, this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? CourseColors.primaryBlue.withOpacity(0.15) : CourseColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? CourseColors.primaryBlue : CourseColors.border),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isActive ? CourseColors.primaryBlue : (isCompleted ? CourseColors.success.withOpacity(0.15) : CourseColors.border),
            shape: BoxShape.circle,
          ),
          child: isCompleted
              ? const Icon(Icons.check, color: CourseColors.success, size: 18)
              : isActive
                  ? const Icon(Icons.play_arrow, color: Colors.white, size: 20)
                  : isLocked
                      ? const Icon(Icons.lock, color: CourseColors.yellow, size: 16)
                      : Center(child: Text('$index', style: const TextStyle(color: CourseColors.textSecondary, fontSize: 13))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: isActive ? CourseColors.textPrimary : CourseColors.textSecondary, fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
            const SizedBox(height: 4),
            Text(duration, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
          ],
        )),
        if (isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: CourseColors.primaryBlue, borderRadius: BorderRadius.circular(6)),
            child: const Text('Playing', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB: ABOUT COURSE
// ─────────────────────────────────────────────────────────────
class _AboutCourseTab extends StatelessWidget {
  const _AboutCourseTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('About This Course',
            style: TextStyle(color: CourseColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text(
          'This Physics course is designed for Grade 12 students to help you master all core concepts in a simple, visual and easy-to-understand way. Each lesson includes clear explanations, real-life examples and practice questions to strengthen your understanding.',
          style: TextStyle(color: CourseColors.textSecondary, fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: CourseColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CourseColors.border),
          ),
          child: Column(children: const [
            _InfoRow(icon: Icons.menu_book_outlined, label: 'Course Level', value: 'Grade 12'),
            Divider(color: CourseColors.border, height: 1, indent: 60),
            _InfoRow(icon: Icons.science_outlined, label: 'Subject', value: 'Physics'),
            Divider(color: CourseColors.border, height: 1, indent: 60),
            _InfoRow(icon: Icons.play_circle_outline, label: 'Total Lessons', value: '36 Lessons'),
            Divider(color: CourseColors.border, height: 1, indent: 60),
            _InfoRow(icon: Icons.access_time_outlined, label: 'Total Duration', value: '18h 45m'),
            Divider(color: CourseColors.border, height: 1, indent: 60),
            _InfoRow(icon: Icons.language_outlined, label: 'Language', value: 'English'),
            Divider(color: CourseColors.border, height: 1, indent: 60),
            _InfoRow(icon: Icons.card_membership_outlined, label: 'Certificate', value: 'Yes, after completion'),
          ]),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, color: CourseColors.primaryBlue, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 13))),
        Text(value, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB: RESOURCES
// ─────────────────────────────────────────────────────────────
class _ResourcesTab extends StatelessWidget {
  const _ResourcesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Lesson Resources',
            style: TextStyle(color: CourseColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        _ResourceTile(icon: Icons.picture_as_pdf, label: 'Chapter 1 Notes.pdf', size: '2.4 MB', color: Colors.red.shade400),
        _ResourceTile(icon: Icons.picture_as_pdf, label: 'Practice Questions.pdf', size: '1.1 MB', color: Colors.red.shade400),
        _ResourceTile(icon: Icons.image_outlined, label: 'Diagram Set 1.jpg', size: '540 KB', color: CourseColors.primaryBlue),
        _ResourceTile(icon: Icons.assignment_outlined, label: 'Chapter Quiz.pdf', size: '850 KB', color: CourseColors.success),
      ],
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final IconData icon;
  final String label, size;
  final Color color;
  const _ResourceTile({required this.icon, required this.label, required this.size, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CourseColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CourseColors.border),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(size, style: const TextStyle(color: CourseColors.textSecondary, fontSize: 11)),
        ])),
        IconButton(
          icon: const Icon(Icons.download_outlined, color: CourseColors.primaryBlue),
          onPressed: () {},
        ),
      ]),
    );
  }
}
