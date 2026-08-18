import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../core/theme.dart';
import '../../config/api_config.dart';
import '../../models/chapter_model.dart';
import '../../models/lesson_model.dart';
import '../../models/course_model.dart';
import '../../services/course_service.dart';

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
                                  if (l.isFree) ...[const SizedBox(width: 4), _badge('FREE', AppColors.success)],
                                ]),
                                Text('Lesson ${l.lessonNumber} • ${l.durationMinutes} min',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                              ]),
                            ),
                            Column(mainAxisSize: MainAxisSize.min, children: [
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
  bool _isFree = false;
  bool _isSubmitting = false;

  bool get _isEditing => widget.lessonToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final l = widget.lessonToEdit!;
      _titleCtrl.text = l.title;
      _lessonNumCtrl.text = l.lessonNumber.toString();
      _durationCtrl.text = l.durationMinutes.toString();
      _isFree = l.isFree;
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
    setState(() => _isSubmitting = true);

    try {
      final uri = _isEditing
          ? Uri.parse('$apiBaseUrl/admin/lessons/${widget.lessonToEdit!.id}')
          : Uri.parse('$apiBaseUrl/admin/lessons');

      final request = http.MultipartRequest(_isEditing ? 'PUT' : 'POST', uri);
      request.fields['chapter_id'] = widget.chapter.id;
      request.fields['course_id'] = widget.course.id;
      request.fields['title'] = _titleCtrl.text.trim();
      request.fields['lesson_number'] = _lessonNumCtrl.text.trim();
      request.fields['duration_minutes'] = _durationCtrl.text.trim();
      request.fields['is_free'] = _isFree.toString();

      Future<void> addFile(File file, String field) async {
        final mime = lookupMimeType(file.path)?.split('/');
        request.files.add(await http.MultipartFile.fromPath(
          field, file.path,
          contentType: mime != null ? MediaType(mime[0], mime[1]) : MediaType('application', 'octet-stream'),
        ));
      }

      if (_thumbnailFile != null) await addFile(_thumbnailFile!, 'thumbnail');
      if (_videoFile != null) await addFile(_videoFile!, 'video');
      if (_notesFile != null) await addFile(_notesFile!, 'notes');

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnack(_isEditing ? 'Lesson updated!' : 'Lesson created!');
        widget.onSuccess();
        if (mounted) Navigator.pop(context);
      } else {
        _showSnack('Failed: ${res.body}', isError: true);
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3), width: 1.5),
                    ),
                    child: Row(children: [
                      Icon(Icons.videocam_rounded, color: const Color(0xFF2563EB).withOpacity(0.7), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _videoFile != null
                              ? _videoFile!.path.split('/').last.split('\\').last
                              : (existVideo != null ? '✔ Video uploaded (tap to replace)' : 'Tap to upload video (MP4)'),
                          style: TextStyle(fontSize: 12, color: _videoFile != null || existVideo != null ? AppColors.textDark : AppColors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_videoFile != null)
                        Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    ]),
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

                // ── Is Free Toggle ────────────────────
                SwitchListTile(
                  title: const Text('Is Free Lesson?', style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _isFree,
                  activeColor: const Color(0xFF16A34A),
                  onChanged: (v) => setState(() => _isFree = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isEditing ? 'Save Changes' : 'Create Lesson',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
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
