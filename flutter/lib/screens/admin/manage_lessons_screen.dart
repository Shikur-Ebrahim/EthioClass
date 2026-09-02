import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import '../../core/theme.dart';
import '../../config/api_config.dart';
import '../../models/chapter_model.dart';
import '../../models/lesson_model.dart';
import '../../models/course_model.dart';
import '../../services/course_service.dart';
import 'manage_quiz_screen.dart';

class ManageLessonsScreen extends StatefulWidget {
  final Chapter chapter;
  final Course course;

  const ManageLessonsScreen({super.key, required this.chapter, required this.course});

  @override
  State<ManageLessonsScreen> createState() => _ManageLessonsScreenState();
}

class _ManageLessonsScreenState extends State<ManageLessonsScreen> {
  bool _isLoading = false;
  List<Lesson> _lessons = [];

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/lessons?chapter_id=${widget.chapter.id}'));
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _lessons = data.map((j) => Lesson.fromJson(j as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _openAddForm() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _LessonFormScreen(
        chapter: widget.chapter,
        course: widget.course,
        nextLessonNumber: _lessons.isEmpty ? 1 : (_lessons.last.lessonNumber + 1),
        onSuccess: _loadLessons,
      ),
    ));
  }

  void _openEditForm(Lesson lesson) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _LessonFormScreen(
        chapter: widget.chapter,
        course: widget.course,
        lessonToEdit: lesson,
        nextLessonNumber: lesson.lessonNumber,
        onSuccess: _loadLessons,
      ),
    ));
  }

  Future<void> _deleteLesson(Lesson lesson) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Lesson'),
        content: Text('Delete "${lesson.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await http.delete(Uri.parse('$apiBaseUrl/admin/lessons/${lesson.id}'));
      if (res.statusCode == 200) {
        _showSnack('Lesson deleted');
        _loadLessons();
      } else {
        _showSnack('Failed to delete', isError: true);
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text('Lessons: ${widget.chapter.title}',
            style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 15),
            overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _openAddForm,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Lesson'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))
          : _lessons.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.play_lesson_outlined, size: 60, color: AppColors.grey.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text('No lessons yet', style: TextStyle(color: AppColors.grey, fontSize: 16)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _openAddForm,
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Lesson'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ]),
                )
              : RefreshIndicator(
                  color: const Color(0xFF16A34A),
                  onRefresh: _loadLessons,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _lessons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final l = _lessons[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                        ),
                        child: Row(
                          children: [
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: Stack(fit: StackFit.expand, children: [
                                  l.thumbnailUrl != null && l.thumbnailUrl!.isNotEmpty
                                      ? Image.network('$apiBaseUrl/media/${l.thumbnailUrl!}', fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _fallback())
                                      : _fallback(),
                                  const Center(child: Icon(Icons.play_circle_filled, color: Colors.white70, size: 24)),
                                ]),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(l.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  if (l.videoUrl != null) _badge('Video', const Color(0xFF2563EB)),
                                  if (l.notesUrl != null) ...[const SizedBox(width: 4), _badge('Notes', const Color(0xFFD97706))],
                                ]),
                                Text('Lesson ${l.lessonNumber} • ${l.durationMinutes} min',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                              ]),
                            ),
                            Column(mainAxisSize: MainAxisSize.min, children: [
                              // Quiz button
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => ManageQuizScreen(lesson: l),
                                )),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  margin: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.quiz_rounded, size: 12, color: Color(0xFF7C3AED)),
                                    SizedBox(width: 4),
                                    Text('Quiz', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED))),
                                  ]),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, color: Color(0xFF16A34A), size: 20),
                                onPressed: () => _openEditForm(l),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                                onPressed: () => _deleteLesson(l),
                              ),
                            ]),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _fallback() => Container(
        color: const Color(0xFF16A34A).withOpacity(0.15),
        child: const Icon(Icons.play_lesson_rounded, color: Color(0xFF16A34A), size: 24),
      );

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
      );
}

// ── LESSON FORM SCREEN ─────────────────────────────────────────────────────
class _LessonFormScreen extends StatefulWidget {
  final Chapter chapter;
  final Course course;
  final Lesson? lessonToEdit;
  final int nextLessonNumber;
  final VoidCallback onSuccess;

  const _LessonFormScreen({
    required this.chapter,
    required this.course,
    this.lessonToEdit,
    required this.nextLessonNumber,
    required this.onSuccess,
  });

  @override
  State<_LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends State<_LessonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _lessonNumCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();

  File? _thumbnailFile;
  File? _videoFile;
  File? _notesFile;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;
  CancelToken? _cancelToken;


  bool get _isEditing => widget.lessonToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final l = widget.lessonToEdit!;
      _titleCtrl.text = l.title;
      _lessonNumCtrl.text = l.lessonNumber.toString();
      _durationCtrl.text = l.durationMinutes.toString();
    } else {
      _lessonNumCtrl.text = widget.nextLessonNumber.toString();
      _durationCtrl.text = '0';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _lessonNumCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickThumbnail() async {
    final p = ImagePicker();
    final picked = await p.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1080);
    if (picked != null) setState(() => _thumbnailFile = File(picked.path));
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      setState(() => _videoFile = File(result.files.single.path!));
    }
  }

  Future<void> _pickNotes() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'ppt', 'pptx', 'doc', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _notesFile = File(result.files.single.path!));
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
    });
    _cancelToken = CancelToken();

    try {
      final uri = _isEditing
          ? '$apiBaseUrl/admin/lessons/${widget.lessonToEdit!.id}'
          : '$apiBaseUrl/admin/lessons';

      final dio = Dio();

      String? presignedVideoKey;
      if (_videoFile != null) {
        final mime = lookupMimeType(_videoFile!.path) ?? 'application/octet-stream';
        final fileName = _videoFile!.path.split('/').last;

        final presignRes = await dio.post(
          '$apiBaseUrl/admin/lessons/presigned-url',
          data: {
            'filename': fileName,
            'content_type': mime,
          },
          cancelToken: _cancelToken,
        );

        if (presignRes.statusCode != 200) {
          throw Exception('Failed to get upload URL: ${presignRes.data}');
        }

        final uploadUrl = presignRes.data['url'];
        presignedVideoKey = presignRes.data['key'];
        
        final videoLen = await _videoFile!.length();

        await dio.put(
          uploadUrl,
          data: _videoFile!.openRead(),
          options: Options(
            headers: {
              Headers.contentLengthHeader: videoLen,
              Headers.contentTypeHeader: mime,
            },
          ),
          cancelToken: _cancelToken,
          onSendProgress: (count, total) {
            if (total > 0 && mounted) {
              setState(() {
                _uploadProgress = count / total;
              });
            }
          },
        );
      }

      var formMap = {
        'chapter_id': widget.chapter.id,
        'title': _titleCtrl.text.trim(),
        'lesson_number': _lessonNumCtrl.text.trim(),
        'duration_minutes': _durationCtrl.text.trim(),
      };
      if (presignedVideoKey != null) {
        formMap['video_key'] = presignedVideoKey;
      }
      var formData = FormData.fromMap(formMap);

      Future<void> addFile(File file, String field) async {
        final mime = lookupMimeType(file.path)?.split('/');
        formData.files.add(MapEntry(
          field,
          await MultipartFile.fromFile(
            file.path,
            contentType: mime != null ? MediaType(mime[0], mime[1]) : MediaType('application', 'octet-stream'),
          ),
        ));
      }

      if (_thumbnailFile != null) await addFile(_thumbnailFile!, 'thumbnail');
      if (_notesFile != null) await addFile(_notesFile!, 'notes');

      final response = await (_isEditing ? dio.put : dio.post)(
        uri,
        data: formData,
        cancelToken: _cancelToken,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnack(_isEditing ? 'Lesson updated!' : 'Lesson created!');
        widget.onSuccess();
        if (mounted) Navigator.pop(context);
      } else {
        _showSnack('Failed: ${response.data}', isError: true);
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
         _showSnack('Upload cancelled');
      } else {
         _showSnack('Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() { _isSubmitting = false; _uploadProgress = 0.0; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final existThumb = widget.lessonToEdit?.thumbnailUrl;
    final existVideo = widget.lessonToEdit?.videoUrl;
    final existNotes = widget.lessonToEdit?.notesUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text(_isEditing ? 'Edit Lesson' : 'Add Lesson',
            style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Thumbnail Picker ──────────────────
                GestureDetector(
                  onTap: _pickThumbnail,
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.3), width: 2),
                      image: _thumbnailFile != null
                          ? DecorationImage(image: FileImage(_thumbnailFile!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _thumbnailFile != null
                        ? null
                        : (existThumb != null && existThumb.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(fit: StackFit.expand, children: [
                                  Image.network('$apiBaseUrl/media/$existThumb', fit: BoxFit.cover),
                                  Container(color: Colors.black.withOpacity(0.3)),
                                  const Center(child: Icon(Icons.edit, color: Colors.white, size: 26)),
                                ]),
                              )
                            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.add_photo_alternate_rounded, size: 32, color: const Color(0xFF16A34A).withOpacity(0.5)),
                                const SizedBox(height: 4),
                                Text('Lesson Thumbnail', style: TextStyle(color: const Color(0xFF16A34A).withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
                              ])),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Lesson Number ──────────────────────
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lessonNumCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDec('Lesson Number'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDec('Duration (min)'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final num = int.tryParse(v);
                        if (num == null || num <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                // ── Title ──────────────────────────────
                TextFormField(
                  controller: _titleCtrl,
                  decoration: _inputDec('Lesson Title'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // ── Video Upload ───────────────────────
                const Text('Video', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickVideo,
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.4), width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _videoFile != null || existVideo != null ? Icons.check_circle : Icons.videocam_rounded,
                          color: _videoFile != null || existVideo != null ? AppColors.success : const Color(0xFF2563EB).withOpacity(0.8),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _videoFile != null
                              ? _videoFile!.path.split('/').last.split('\\').last
                              : (existVideo != null ? '✔ Video uploaded (tap to replace)' : 'Tap to upload video (MP4 up to 1GB)'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _videoFile != null || existVideo != null ? AppColors.textDark : const Color(0xFF2563EB).withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Notes Upload ───────────────────────
                const Text('Notes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickNotes,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD97706).withOpacity(0.3), width: 1.5),
                    ),
                    child: Row(children: [
                      Icon(Icons.description_rounded, color: const Color(0xFFD97706).withOpacity(0.7), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _notesFile != null
                              ? _notesFile!.path.split('/').last.split('\\').last
                              : (existNotes != null ? '✔ Notes uploaded (tap to replace)' : 'Tap to upload notes (PDF/PPT)'),
                          style: TextStyle(fontSize: 12, color: _notesFile != null || existNotes != null ? AppColors.textDark : AppColors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_notesFile != null)
                        Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 20),

                if (_isSubmitting) ...[
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_uploadProgress * 100).toStringAsFixed(1)}% uploaded',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMedium),
                  ),
                  TextButton(
                    onPressed: () => _cancelToken?.cancel(),
                    child: const Text('Cancel Upload', style: TextStyle(color: AppColors.error)),
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _isEditing ? 'Save Changes' : 'Create Lesson',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.background,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );
}
