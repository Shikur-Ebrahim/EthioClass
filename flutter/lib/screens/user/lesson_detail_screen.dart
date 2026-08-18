import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../config/api_config.dart';
import '../../models/lesson_model.dart';
import '../../models/chapter_model.dart';

class LessonDetailScreen extends StatefulWidget {
  final String chapterTitle;
  final bool isLocked;
  final String? thumbnailUrl;
  final int chapterNumber;
  final String? chapterDescription;
  // Full lesson list for this chapter (user navigates between them)
  final List<Lesson> lessons;
  final int initialLessonIndex;

  const LessonDetailScreen({
    super.key,
    required this.chapterTitle,
    this.isLocked = false,
    this.thumbnailUrl,
    this.chapterNumber = 1,
    this.chapterDescription,
    this.lessons = const [],
    this.initialLessonIndex = 0,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _currentLessonIndex;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _videoLoading = false;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    _currentLessonIndex = widget.initialLessonIndex;
    _tabController = TabController(length: 3, vsync: this);
    _initVideo();
  }

  Lesson? get _currentLesson =>
      widget.lessons.isNotEmpty && _currentLessonIndex < widget.lessons.length
          ? widget.lessons[_currentLessonIndex]
          : null;

  Future<void> _initVideo() async {
    final lesson = _currentLesson;
    if (lesson == null || lesson.videoUrl == null || lesson.videoUrl!.isEmpty) return;

    setState(() { _videoLoading = true; _videoError = false; });

    try {
      _videoController?.dispose();
      _chewieController?.dispose();

      final videoUri = Uri.parse('$apiBaseUrl/media/${lesson.videoUrl!}');
      _videoController = VideoPlayerController.networkUrl(videoUri);
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: _bannerPlaceholder(),
      );

      if (mounted) setState(() => _videoLoading = false);
    } catch (e) {
      if (mounted) setState(() { _videoLoading = false; _videoError = true; });
    }
  }

  void _selectLesson(int index) {
    if (index == _currentLessonIndex) return;
    setState(() {
      _currentLessonIndex = index;
      _videoLoading = false;
      _videoError = false;
      _chewieController?.dispose();
      _chewieController = null;
      _videoController?.dispose();
      _videoController = null;
    });
    _initVideo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _currentLesson;
    final thumbUrl = lesson?.thumbnailUrl ?? widget.thumbnailUrl;
    final title = lesson?.title ?? widget.chapterTitle;
    final desc = widget.chapterDescription;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Video / Banner Header ──────────────────────────────────
          Container(
            height: 230,
            width: double.infinity,
            color: Colors.black,
            child: SafeArea(
              bottom: false,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video player or banner
                  if (_chewieController != null)
                    Chewie(controller: _chewieController!)
                  else if (_videoLoading)
                    Stack(fit: StackFit.expand, children: [
                      _buildBannerImage(thumbUrl),
                      const Center(child: CircularProgressIndicator(color: Colors.white)),
                    ])
                  else
                    Stack(fit: StackFit.expand, children: [
                      _buildBannerImage(thumbUrl),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.65)],
                          ),
                        ),
                      ),
                      if (lesson?.videoUrl != null)
                        Center(
                          child: GestureDetector(
                            onTap: _initVideo,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 16)],
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 28),
                          ),
                        ),
                    ]),

                  // Back + more
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

                  // Title + error overlay at bottom
                  if (_chewieController == null)
                    Positioned(
                      bottom: 16,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_videoError)
                            const Text('Could not load video', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                          Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (lesson != null)
                            Text(
                              'Lesson ${lesson.lessonNumber}  •  ${lesson.durationMinutes} min',
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Chapter Description ────────────────────────────────────
          if (desc != null && desc.isNotEmpty)
            Container(
              width: double.infinity,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Text(
                desc,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMedium, height: 1.55),
              ),
            ),

          // ── Tabs ───────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.grey,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [Tab(text: 'Video'), Tab(text: 'Notes'), Tab(text: 'Quiz')],
            ),
          ),

          // ── Tab Content ────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVideoTab(lesson),
                _buildNotesTab(lesson),
                _buildQuizTab(lesson),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── VIDEO TAB: list of lessons ─────────────────────────────────
  Widget _buildVideoTab(Lesson? active) {
    if (widget.lessons.isEmpty) {
      return const Center(child: Text('No lessons yet', style: TextStyle(color: AppColors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.lessons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final l = widget.lessons[i];
        final isActive = i == _currentLessonIndex;
        return GestureDetector(
          onTap: () => _selectLesson(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.greyLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isActive
                      ? const Icon(Icons.pause_rounded, color: Colors.white, size: 20)
                      : Icon(Icons.play_arrow_rounded, color: AppColors.grey, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.title,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isActive ? AppColors.primary : AppColors.textDark)),
                      const SizedBox(height: 2),
                      Text('${l.durationMinutes} min',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                    ],
                  ),
                ),
                if (l.isFree)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('FREE',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.success)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── NOTES TAB ──────────────────────────────────────────────────
  Widget _buildNotesTab(Lesson? lesson) {
    if (lesson?.notesUrl == null || lesson!.notesUrl!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 50, color: AppColors.grey),
            SizedBox(height: 12),
            Text('No notes for this lesson', style: TextStyle(color: AppColors.grey)),
          ],
        ),
      );
    }

    final notesUrl = '$apiBaseUrl/media/${lesson.notesUrl!}';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.description_rounded, color: Color(0xFFD97706), size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Notes Available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 8),
            const Text('Tap below to open the notes document',
                style: TextStyle(fontSize: 13, color: AppColors.textMedium), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(notesUrl);
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open Notes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── QUIZ TAB ───────────────────────────────────────────────────
  Widget _buildQuizTab(Lesson? lesson) {
    if (lesson == null) {
      return const Center(child: Text('Select a lesson first', style: TextStyle(color: AppColors.grey)));
    }
    return _QuizSection(lessonId: lesson.id);
  }

  Widget _buildBannerImage(String? thumbUrl) {
    if (thumbUrl != null && thumbUrl.isNotEmpty) {
      return Image.network(
        '$apiBaseUrl/media/$thumbUrl',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultBanner(),
      );
    }
    return _defaultBanner();
  }

  Widget _defaultBanner() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF16A34A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );

  Widget _bannerPlaceholder() => Container(color: Colors.black);
}

// ── QUIZ SECTION ──────────────────────────────────────────────────────────
class _QuizSection extends StatefulWidget {
  final String lessonId;
  const _QuizSection({required this.lessonId});

  @override
  State<_QuizSection> createState() => _QuizSectionState();
}

class _QuizSectionState extends State<_QuizSection> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];
  Map<int, String> _selectedAnswers = {};
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/quizzes?lesson_id=${widget.lessonId}'));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _questions = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _score => _questions.asMap().entries.where((e) {
        final q = e.value;
        return _selectedAnswers[e.key] == q['correct_answer'];
      }).length;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_questions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 50, color: AppColors.grey),
            SizedBox(height: 12),
            Text('No quiz for this lesson', style: TextStyle(color: AppColors.grey)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_submitted) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _score >= _questions.length / 2 ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _score >= _questions.length / 2 ? AppColors.success : AppColors.error),
              ),
              child: Column(
                children: [
                  Text(
                    '$_score / ${_questions.length}',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: _score >= _questions.length / 2 ? AppColors.success : AppColors.error),
                  ),
                  Text(
                    _score >= _questions.length / 2 ? '🎉 Great job!' : 'Keep practicing!',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                ],
              ),
            ),
          ],
          ..._questions.asMap().entries.map((e) {
            final q = e.value;
            final idx = e.key;
            return _QuizCard(
              question: q,
              index: idx,
              selected: _selectedAnswers[idx],
              submitted: _submitted,
              onSelect: _submitted
                  ? null
                  : (ans) => setState(() => _selectedAnswers[idx] = ans),
            );
          }),
          const SizedBox(height: 16),
          if (!_submitted)
            ElevatedButton(
              onPressed: _selectedAnswers.length == _questions.length
                  ? () => setState(() => _submitted = true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Submit Quiz', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            )
          else
            OutlinedButton.icon(
              onPressed: () => setState(() { _submitted = false; _selectedAnswers = {}; }),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final int index;
  final String? selected;
  final bool submitted;
  final void Function(String)? onSelect;

  const _QuizCard({
    required this.question,
    required this.index,
    this.selected,
    this.submitted = false,
    this.onSelect,
  });

  Color _optionColor(String option) {
    if (!submitted) {
      return selected == option ? AppColors.primary.withOpacity(0.1) : AppColors.surface;
    }
    if (option == question['correct_answer']) return AppColors.success.withOpacity(0.15);
    if (selected == option) return AppColors.error.withOpacity(0.15);
    return AppColors.surface;
  }

  @override
  Widget build(BuildContext context) {
    final options = ['A', 'B', 'C', 'D'];
    final optionValues = {
      'A': question['option_a'],
      'B': question['option_b'],
      'C': question['option_c'],
      'D': question['option_d'],
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${index + 1}. ${question['question']}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          ...options.map((opt) => GestureDetector(
                onTap: () => onSelect?.call(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _optionColor(opt),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected == opt ? AppColors.primary : AppColors.greyLight,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text('$opt. ', style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected == opt ? AppColors.primary : AppColors.textMedium,
                        fontSize: 13,
                      )),
                      Expanded(child: Text(optionValues[opt] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textDark))),
                      if (submitted && opt == question['correct_answer'])
                        const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                      if (submitted && selected == opt && opt != question['correct_answer'])
                        const Icon(Icons.cancel, color: AppColors.error, size: 18),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
