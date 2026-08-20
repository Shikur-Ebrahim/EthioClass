import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../config/api_config.dart';
import '../../models/lesson_model.dart';
import '../../models/chapter_model.dart';
import '../../services/download_service.dart';
import '../../services/progress_service.dart';
import '../../services/bookmark_service.dart';
import '../../models/downloaded_lesson_model.dart';

class LessonDetailScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String? courseThumbnailUrl;
  final int courseTotalLessons;
  final String chapterTitle;
  final bool isLocked;
  final String? thumbnailUrl;
  final int chapterNumber;
  final String? chapterDescription;
  // Full lesson list for this chapter (user navigates between them)
  final List<Lesson> lessons;
  final int initialLessonIndex;
  final int initialTab;

  const LessonDetailScreen({
    super.key,
    this.courseId = '',
    this.courseTitle = 'Course',
    this.courseThumbnailUrl,
    this.courseTotalLessons = 1,
    required this.chapterTitle,
    this.isLocked = false,
    this.thumbnailUrl,
    this.chapterNumber = 1,
    this.chapterDescription,
    this.lessons = const [],
    this.initialLessonIndex = 0,
    this.initialTab = 0,
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

  Map<String, DownloadedLesson> _downloadedLessons = {};
  Map<String, int> _remoteSizes = {};
  // Track local progress for UI refresh trigger
  final Map<String, double> _downloadingProgress = {};

  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _currentLessonIndex = widget.initialLessonIndex;
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _loadAllDownloadStatuses().then((_) {
      _loadRemoteSizes();
    });
    _checkBookmarkStatus();
    _initVideo();
    // Save last watched position for "Continue Learning"
    _saveLastWatched();
    // Re-attach to any downloads that are still running
    for (final lesson in widget.lessons) {
      if (DownloadService.instance.isDownloading(lesson.id)) {
        final notifier = DownloadService.instance.progressNotifiers[lesson.id];
        _downloadingProgress[lesson.id] = notifier?.value ?? 0.0;
        notifier?.addListener(() {
          if (mounted) setState(() => _downloadingProgress[lesson.id] = notifier.value);
        });
      }
    }
  }

  void _saveLastWatched() {
    if (widget.courseId.isEmpty) return;
    final lesson = _currentLesson;
    if (lesson == null) return;
    // Use chapter id from lesson if available, else use lesson id as fallback key
    final chapterId = lesson.chapterId.isNotEmpty ? lesson.chapterId : widget.chapterTitle;
    ProgressService.instance.saveLastWatched(
      courseId: widget.courseId,
      chapterId: chapterId,
      lessonIndex: _currentLessonIndex,
    );
  }

  Future<void> _checkBookmarkStatus() async {
    final lesson = _currentLesson;
    if (lesson == null) return;
    try {
      final bookmarks = await BookmarkService.instance.getBookmarks();
      final lessons = bookmarks['lessons'] as List<dynamic>? ?? [];
      setState(() {
        _isBookmarked = lessons.any((l) => l['id'] == lesson.id);
      });
    } catch (e) {
      debugPrint('Failed to check bookmark status: $e');
    }
  }

  Future<void> _toggleBookmark() async {
    final lesson = _currentLesson;
    if (lesson == null) return;
    
    final wasBookmarked = _isBookmarked;
    setState(() => _isBookmarked = !_isBookmarked); // Optimistic update
    
    try {
      if (wasBookmarked) {
        await BookmarkService.instance.removeLessonBookmark(lesson.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bookmark removed')));
      } else {
        await BookmarkService.instance.addLessonBookmark(
          lessonId: lesson.id,
          courseId: widget.courseId.isNotEmpty ? widget.courseId : (lesson.chapterId.isNotEmpty ? lesson.chapterId : ''), // Fallback
          chapterId: lesson.chapterId,
        );
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson bookmarked!')));
      }
    } catch (e) {
      setState(() => _isBookmarked = wasBookmarked); // Revert on failure
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update bookmark')));
    }
  }

  Future<void> _autoAddBookmark(Lesson lesson) async {
    setState(() => _isBookmarked = true);
    try {
      await BookmarkService.instance.addLessonBookmark(
        lessonId: lesson.id,
        courseId: widget.courseId.isNotEmpty ? widget.courseId : (lesson.chapterId.isNotEmpty ? lesson.chapterId : ''),
        chapterId: lesson.chapterId,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson auto-bookmarked (finished)!')));
    } catch (e) {
      debugPrint('Failed auto-bookmark: $e');
    }
  }

  Lesson? get _currentLesson =>
      widget.lessons.isNotEmpty && _currentLessonIndex < widget.lessons.length
          ? widget.lessons[_currentLessonIndex]
          : null;

  Future<void> _loadAllDownloadStatuses() async {
    final allDownloads = await DownloadService.instance.getDownloadedLessons();
    final Map<String, DownloadedLesson> map = {};
    for (var dl in allDownloads) {
      map[dl.lesson.id] = dl;
    }
    if (mounted) {
      setState(() {
        _downloadedLessons = map;
      });
    }
  }

  Future<void> _loadRemoteSizes() async {
    for (var l in widget.lessons) {
      if (_downloadedLessons.containsKey(l.id)) continue;
      DownloadService.instance.getLessonSize(l).then((size) {
        if (mounted) {
          setState(() {
            _remoteSizes[l.id] = size; // Sets to 0 if not found, which will hide the spinner
          });
        }
      });
    }
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

  Future<void> _initVideo() async {
    final lesson = _currentLesson;
    if (lesson == null) return;
    
    final downloadedData = _downloadedLessons[lesson.id];
    final isDownloaded = downloadedData != null;

    // Only abort if no video url AND no local path
    if ((lesson.videoUrl == null || lesson.videoUrl!.isEmpty) && downloadedData?.localVideoPath == null) return;

    setState(() { _videoLoading = true; _videoError = false; });

    try {
      _videoController?.dispose();
      _chewieController?.dispose();

      if (isDownloaded && downloadedData?.localVideoPath != null) {
        final file = File(downloadedData!.localVideoPath);
        if (await file.exists()) {
          _videoController = VideoPlayerController.file(file);
        } else {
          // Fallback to network if local file missing
          final videoUri = Uri.parse('$apiBaseUrl/media/${lesson.videoUrl!}');
          _videoController = VideoPlayerController.networkUrl(videoUri);
        }
      } else {
        final videoUri = Uri.parse('$apiBaseUrl/media/${lesson.videoUrl!}');
        _videoController = VideoPlayerController.networkUrl(videoUri);
      }
      
      await _videoController!.initialize();

      // Restore last watched timestamp
      final savedSeconds = ProgressService.instance.getVideoTimestamp(lesson.id);
      if (savedSeconds > 0) {
        await _videoController!.seekTo(Duration(seconds: savedSeconds));
      }

      int lastSavedSecond = -1;
      bool _autoBookmarked = false; // Flag to prevent multiple calls
      
      _videoController!.addListener(() {
        if (!mounted || _videoController == null || !_videoController!.value.isInitialized) return;
        
        final position = _videoController!.value.position;
        final duration = _videoController!.value.duration;
        
        if (duration.inMilliseconds > 0) {
          // Auto-complete and Auto-bookmark if watched 85% or more
          if (position.inMilliseconds / duration.inMilliseconds > 0.85) {
            if (!ProgressService.instance.isLessonCompleted(lesson.id)) {
              ProgressService.instance.markLessonComplete(widget.courseId, lesson.id);
            }
            
            // Trigger auto-bookmark robustly at 85% completion
            if (!_autoBookmarked && !_isBookmarked) {
              _autoBookmarked = true; // prevent firing multiple times
              _autoAddBookmark(lesson);
            }
          }
          
          // Save timestamp periodically (only once per second)
          final currentSecond = position.inSeconds;
          if (currentSecond != lastSavedSecond && currentSecond > 0 && currentSecond < duration.inSeconds) {
            lastSavedSecond = currentSecond;
            ProgressService.instance.saveVideoTimestamp(lesson.id, currentSecond);
          }
        }
      });

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
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
    // Save position so "Continue Learning" resumes here
    _saveLastWatched();
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
            height: 280,
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
                        Row(
                          children: [
                            IconButton(
                              onPressed: _toggleBookmark,
                              icon: Icon(
                                _isBookmarked ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                                color: _isBookmarked ? Colors.amber : Colors.white,
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                            ),
                          ],
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.grey,
          title: Text(
            '${widget.chapterNumber}. ${widget.chapterTitle}',
            style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 16),
          ),
          children: widget.lessons.asMap().entries.map((entry) {
            final i = entry.key;
            final l = entry.value;
            final isActive = i == _currentLessonIndex;
            return ValueListenableBuilder<Set<String>>(
              valueListenable: ProgressService.instance.completedLessonsNotifier,
              builder: (context, completedLessons, child) {
                final isCompleted = completedLessons.contains(l.id);
                return GestureDetector(
                  onTap: () => _selectLesson(i),
                  child: AnimatedContainer(
                    margin: const EdgeInsets.only(bottom: 10),
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
                      width: 100,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.greyLight,
                        borderRadius: BorderRadius.circular(8),
                        image: l.thumbnailUrl != null
                            ? DecorationImage(
                                image: NetworkImage('$apiBaseUrl/media/${l.thumbnailUrl!}'),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (l.thumbnailUrl == null)
                            const Center(child: Icon(Icons.ondemand_video_rounded, color: AppColors.grey, size: 20)),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: isActive
                                  ? const Icon(Icons.pause_rounded, color: Colors.white, size: 20)
                                  : const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
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
                          Text('${l.lessonNumber}. ${l.title}',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isActive ? AppColors.primary : (isCompleted ? AppColors.grey : AppColors.textDark))),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text('${l.durationMinutes} min',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                              if (_downloadedLessons[l.id] != null) ...[ 
                                const Text('  •  ', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
                                Text(_formatBytes(_downloadedLessons[l.id]!.sizeBytes),
                                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
                              ] else if (_remoteSizes[l.id] != null && _remoteSizes[l.id]! > 0) ...[
                                const Text('  •  ', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
                                Text(_formatBytes(_remoteSizes[l.id]!),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                              ] else if (l.videoUrl != null && l.videoUrl!.isNotEmpty && _downloadedLessons[l.id] == null) ...[
                                const Text('  •  ', style: TextStyle(fontSize: 11, color: AppColors.textMedium)),
                                const SizedBox(
                                  width: 10, height: 10,
                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.grey),
                                ),
                              ],
                            ],
                          ),
                          // Horizontal progress bar when downloading
                          if (_downloadingProgress[l.id] != null) ...[
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _downloadingProgress[l.id]! > 0 ? _downloadingProgress[l.id] : null,
                                backgroundColor: const Color(0xFF22C55E).withOpacity(0.15),
                                color: const Color(0xFF22C55E),
                                minHeight: 5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _downloadingProgress[l.id]! > 0.01
                                  ? '${(_downloadingProgress[l.id]! * 100).toInt()}%  Downloading...'
                                  : 'Starting...',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF22C55E), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Right-side action button
                if (_downloadingProgress[l.id] != null)
                  // Pause button during download
                  GestureDetector(
                    onTap: () {
                      DownloadService.instance.pauseDownload(l.id);
                      setState(() { _downloadingProgress.remove(l.id); });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pause_rounded, size: 16, color: Color(0xFF22C55E)),
                    ),
                  )
                else if (_downloadedLessons[l.id] != null)
                  // Downloaded checkmark
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 14, color: Color(0xFF22C55E)),
                        SizedBox(width: 4),
                        Text('Done', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
                      ],
                    ),
                  )
                else
                  // Download / Resume button
                  GestureDetector(
                    onTap: () async {
                      setState(() { _downloadingProgress[l.id] = 0.0; });
                      // Attach to the progress notifier for live updates
                      DownloadService.instance.downloadLesson(
                        lesson: l,
                        courseTitle: widget.courseTitle,
                        chapterTitle: widget.chapterTitle,
                        courseThumbnailUrl: widget.courseThumbnailUrl ?? widget.thumbnailUrl,
                        courseTotalLessons: widget.courseTotalLessons,
                        onProgress: (p) {
                          if (mounted) {
                            setState(() => _downloadingProgress[l.id] = p);
                          }
                        },
                      ).then((_) async {
                        await _loadAllDownloadStatuses();
                        if (l.id == _currentLesson?.id && mounted) _initVideo();
                        if (mounted) setState(() { _downloadingProgress.remove(l.id); });
                      }).catchError((e) {
                        if (mounted) {
                          setState(() { _downloadingProgress.remove(l.id); });
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Download failed: $e')));
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.greyLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.download_rounded, size: 13, color: AppColors.textMedium),
                          SizedBox(width: 4),
                          Text('Download', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMedium)),
                        ],
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            );
          },
            );
          }).toList(),
        ),
      ),
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
    
    // Automatically mark as complete when they open the notes
    if (widget.courseId.isNotEmpty) {
      ProgressService.instance.markLessonComplete(widget.courseId, lesson.id);
    }

    final downloadedData = _downloadedLessons[lesson.id];
    final isLocal = downloadedData != null && downloadedData.localNotesPath != null;
    final notesUrl = '$apiBaseUrl/media/${lesson.notesUrl!}';
    
    // Check if it's a PDF
    if (notesUrl.toLowerCase().endsWith('.pdf')) {
      return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.greyLight),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: isLocal
            ? SfPdfViewer.file(File(downloadedData.localNotesPath!))
            : SfPdfViewer.network(notesUrl),
        ),
      );
    }

    // For PPT or other types, keep the open button
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
            const Text('Document Available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 8),
            const Text('Tap below to open the document',
                style: TextStyle(fontSize: 13, color: AppColors.textMedium), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(notesUrl);
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open Document'),
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

  // ── QUIZ TAB: all lessons in chapter ──────────────────
  Widget _buildQuizTab(Lesson? lesson) {
    if (widget.lessons.isEmpty) {
      return const Center(child: Text('No lessons in this chapter', style: TextStyle(color: AppColors.grey)));
    }
    return _ChapterQuizSection(lessons: widget.lessons);
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

// ── CHAPTER QUIZ SECTION (all lessons, sequential) ──────────────────
class _ChapterQuizSection extends StatefulWidget {
  final List<Lesson> lessons;
  const _ChapterQuizSection({required this.lessons});

  @override
  State<_ChapterQuizSection> createState() => _ChapterQuizSectionState();
}

class _ChapterQuizSectionState extends State<_ChapterQuizSection> {
  // lessonId -> list of questions
  Map<String, List<Map<String, dynamic>>> _lessonQuizzes = {};
  bool _isLoading = true;
  int _currentLessonGroupIndex = 0;

  // Per lesson group state
  Map<String, Map<int, String>> _selectedAnswers = {};
  Map<String, bool> _submitted = {};

  @override
  void initState() {
    super.initState();
    _loadAllQuizzes();
  }

  Future<void> _loadAllQuizzes() async {
    final results = <String, List<Map<String, dynamic>>>{};
    for (final lesson in widget.lessons) {
      try {
        final downloaded = await DownloadService.instance.getDownloadedLesson(lesson.id);
        if (downloaded != null && downloaded.cachedQuizJson != null) {
          final data = jsonDecode(downloaded.cachedQuizJson!) as List;
          results[lesson.id] = data.cast<Map<String, dynamic>>();
        } else {
          final res = await http.get(Uri.parse('$apiBaseUrl/quizzes?lesson_id=${lesson.id}'));
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body) as List;
            results[lesson.id] = data.cast<Map<String, dynamic>>();
          } else {
            results[lesson.id] = [];
          }
        }
      } catch (_) {
        results[lesson.id] = [];
      }
    }
    // Filter to only lessons that HAVE quizzes
    final filtered = Map.fromEntries(
      results.entries.where((e) => e.value.isNotEmpty),
    );
    if (mounted) setState(() { _lessonQuizzes = filtered; _isLoading = false; });
  }

  // Lessons that have quizzes, in order
  List<Lesson> get _lessonsWithQuiz =>
      widget.lessons.where((l) => (_lessonQuizzes[l.id]?.isNotEmpty ?? false)).toList();

  int get _score {
    int score = 0;
    for (final lesson in _lessonsWithQuiz) {
      final questions = _lessonQuizzes[lesson.id] ?? [];
      final answers = _selectedAnswers[lesson.id] ?? {};
      for (int i = 0; i < questions.length; i++) {
        if (answers[i] == questions[i]['correct_answer']) score++;
      }
    }
    return score;
  }

  int get _totalQuestions {
    return _lessonsWithQuiz.fold(0, (sum, l) => sum + (_lessonQuizzes[l.id]?.length ?? 0));
  }

  bool get _allGroupsDone => _currentLessonGroupIndex >= _lessonsWithQuiz.length;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final lessonsWithQuiz = _lessonsWithQuiz;

    if (lessonsWithQuiz.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 60, color: AppColors.grey),
            SizedBox(height: 12),
            Text('No quizzes available yet', style: TextStyle(fontSize: 15, color: AppColors.grey)),
          ],
        ),
      );
    }

    // Final results screen
    if (_allGroupsDone) {
      return _buildFinalResults(lessonsWithQuiz);
    }

    final currentLesson = lessonsWithQuiz[_currentLessonGroupIndex];
    final questions = _lessonQuizzes[currentLesson.id] ?? [];
    final answers = _selectedAnswers[currentLesson.id] ?? {};
    final isSubmitted = _submitted[currentLesson.id] ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(lessonsWithQuiz.length, (i) {
              final isDone = _submitted[lessonsWithQuiz[i].id] == true;
              final isCurrent = i == _currentLessonGroupIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isCurrent ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isDone ? AppColors.success
                      : isCurrent ? AppColors.primary
                      : AppColors.greyLight,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Lesson name header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF16A34A)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: Center(
                    child: Text('${currentLesson.lessonNumber}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(currentLesson.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                Text('${_currentLessonGroupIndex + 1}/${lessonsWithQuiz.length}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Questions
          ...questions.asMap().entries.map((e) {
            final q = e.value;
            final idx = e.key;
            return _QuizCard(
              question: q,
              index: idx,
              selected: answers[idx],
              submitted: isSubmitted,
              onSelect: isSubmitted ? null : (ans) => setState(() {
                _selectedAnswers[currentLesson.id] ??= {};
                _selectedAnswers[currentLesson.id]![idx] = ans;
              }),
            );
          }),

          const SizedBox(height: 16),

          // Score banner if submitted (Moved to bottom)
          if (isSubmitted) ...[  
            Builder(builder: (_) {
              int score = 0;
              for (int i = 0; i < questions.length; i++) {
                if (answers[i] == questions[i]['correct_answer']) score++;
              }
              final passed = score >= questions.length / 2;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: passed ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: passed ? AppColors.success : AppColors.error),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(passed ? '🎉' : '📖', style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$score / ${questions.length} Correct',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                              color: passed ? AppColors.success : AppColors.error)),
                      Text(passed ? 'Great job on this lesson!' : 'Review and keep going!',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                    ]),
                  ],
                ),
              );
            }),
          ],

          // Submit or Next button
          if (!isSubmitted)
            ElevatedButton(
              onPressed: answers.length == questions.length
                  ? () => setState(() => _submitted[currentLesson.id] = true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.greyLight,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Submit Quiz',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            )
          else
            ElevatedButton.icon(
              onPressed: () => setState(() => _currentLessonGroupIndex++),
              icon: Icon(_currentLessonGroupIndex < lessonsWithQuiz.length - 1
                  ? Icons.arrow_forward_rounded
                  : Icons.emoji_events_rounded),
              label: Text(_currentLessonGroupIndex < lessonsWithQuiz.length - 1
                  ? 'Next Lesson Quiz'
                  : 'See Final Results'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinalResults(List<Lesson> lessonsWithQuiz) {
    final score = _score;
    final total = _totalQuestions;
    final passed = score >= total / 2;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Icon(passed ? Icons.emoji_events_rounded : Icons.school_rounded,
              size: 72, color: passed ? const Color(0xFFFBB024) : AppColors.primary),
          const SizedBox(height: 16),
          Text(passed ? 'Chapter Complete! 🎉' : 'Chapter Quiz Done!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text('$score out of $total correct',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textMedium)),
          const SizedBox(height: 24),
          // Per-lesson summary
          ...lessonsWithQuiz.map((lesson) {
            final questions = _lessonQuizzes[lesson.id] ?? [];
            final answers = _selectedAnswers[lesson.id] ?? {};
            int s = 0;
            for (int i = 0; i < questions.length; i++) {
              if (answers[i] == questions[i]['correct_answer']) s++;
            }
            final p = s >= questions.length / 2;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: p ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(p ? Icons.check_rounded : Icons.close_rounded,
                        color: p ? AppColors.success : AppColors.error, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Lesson ${lesson.lessonNumber}: ${lesson.title}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      Text('$s / ${questions.length} correct',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                    ]),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _currentLessonGroupIndex = 0;
              _selectedAnswers = {};
              _submitted = {};
            }),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry All Quizzes'),
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

// ── INDIVIDUAL QUIZ CARD ──────────────────────────────────────
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
          // Explanation shown after submit
          if (submitted && question['explanation'] != null && question['explanation'].toString().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      question['explanation'].toString(),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
// end of file

