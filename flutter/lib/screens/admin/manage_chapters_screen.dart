import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../core/theme.dart';
import '../../config/api_config.dart';
import '../../models/course_model.dart';
import '../../models/chapter_model.dart';
import '../../services/course_service.dart';
import 'manage_lessons_screen.dart';
import 'manage_exam_screen.dart';

class ManageChaptersScreen extends StatefulWidget {
  final Course course;

  const ManageChaptersScreen({super.key, required this.course});

  @override
  State<ManageChaptersScreen> createState() => _ManageChaptersScreenState();
}

class _ManageChaptersScreenState extends State<ManageChaptersScreen> {
  bool _isLoading = false;
  List<Chapter> _chapters = [];

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    setState(() => _isLoading = true);
    try {
      final chapters = await CourseService().getChapters(widget.course.id);
      if (mounted) {
        setState(() {
          _chapters = chapters;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openAddForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChapterFormScreen(
          courseId: widget.course.id,
          nextChapterNumber: _chapters.isEmpty ? 1 : (_chapters.last.chapterNumber + 1),
          onSuccess: _loadChapters,
        ),
      ),
    );
  }

  void _openEditForm(Chapter chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChapterFormScreen(
          courseId: widget.course.id,
          chapterToEdit: chapter,
          nextChapterNumber: chapter.chapterNumber,
          onSuccess: _loadChapters,
        ),
      ),
    );
  }

  Future<void> _deleteChapter(Chapter chapter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Chapter'),
        content: Text('Delete "${chapter.title}"? This cannot be undone.'),
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

    if (confirmed != true) return;

    try {
      final response = await http.delete(Uri.parse('$apiBaseUrl/admin/chapters/${chapter.id}'));
      if (response.statusCode == 200) {
        _showSnack('Chapter deleted');
        _loadChapters();
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
        title: Text('Chapters: ${widget.course.title}',
            style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _openAddForm,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Chapter'),
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
          : _chapters.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books_rounded, size: 60, color: AppColors.grey.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text('No chapters yet', style: TextStyle(color: AppColors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF16A34A),
                  onRefresh: _loadChapters,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _chapters.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final chap = _chapters[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: AppColors.greyLight, borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                child: Text('${chap.chapterNumber}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark, fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(chap.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                                  if (chap.description != null && chap.description!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(chap.description!, style: const TextStyle(fontSize: 12, color: AppColors.textMedium), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (chap.isFree)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                                child: const Text('FREE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success)),
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.play_lesson_rounded, color: Color(0xFF2563EB), size: 20),
                                  tooltip: 'Manage Lessons',
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => ManageLessonsScreen(chapter: chap, course: widget.course),
                                    ));
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.quiz_rounded, color: Colors.orange, size: 20),
                                  tooltip: 'Manage Exam',
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => ManageExamScreen(chapter: chap),
                                    ));
                                  },
                                ),
                                IconButton(icon: const Icon(Icons.edit_rounded, color: Color(0xFF16A34A), size: 20), onPressed: () => _openEditForm(chap)),
                                IconButton(icon: const Icon(Icons.delete_rounded, color: AppColors.error, size: 20), onPressed: () => _deleteChapter(chap)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ── CHAPTER FORM SCREEN (Add + Edit) ───────────────────────────────────────
class _ChapterFormScreen extends StatefulWidget {
  final String courseId;
  final Chapter? chapterToEdit;
  final int nextChapterNumber;
  final VoidCallback onSuccess;

  const _ChapterFormScreen({
    required this.courseId,
    this.chapterToEdit,
    required this.nextChapterNumber,
    required this.onSuccess,
  });

  @override
  State<_ChapterFormScreen> createState() => _ChapterFormScreenState();
}

class _ChapterFormScreenState extends State<_ChapterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _chapterNumberController = TextEditingController();

  File? _imageFile;
  bool _isSubmitting = false;
  bool _isFree = false;

  bool get _isEditing => widget.chapterToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.chapterToEdit!;
      _titleController.text = c.title;
      if (c.description != null) _descController.text = c.description!;
      _chapterNumberController.text = c.chapterNumber.toString();
      _isFree = c.isFree;
    } else {
      _chapterNumberController.text = widget.nextChapterNumber.toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _chapterNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60, maxWidth: 1080);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final uri = _isEditing
          ? Uri.parse('$apiBaseUrl/admin/chapters/${widget.chapterToEdit!.id}')
          : Uri.parse('$apiBaseUrl/admin/chapters');

      final request = http.MultipartRequest(_isEditing ? 'PUT' : 'POST', uri);

      request.fields['course_id'] = widget.courseId;
      request.fields['title'] = _titleController.text.trim();
      request.fields['description'] = _descController.text.trim();
      request.fields['chapter_number'] = _chapterNumberController.text.trim();
      request.fields['is_free'] = _isFree.toString();

      if (_imageFile != null) {
        final mimeTypeData = lookupMimeType(_imageFile!.path)?.split('/');
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _imageFile!.path,
            contentType: mimeTypeData != null ? MediaType(mimeTypeData[0], mimeTypeData[1]) : MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnack(_isEditing ? 'Chapter updated!' : 'Chapter created!');
        widget.onSuccess();
        if (mounted) Navigator.pop(context);
      } else {
        _showSnack('Failed: ${response.body}', isError: true);
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingThumbnail = widget.chapterToEdit?.thumbnailUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text(_isEditing ? 'Edit Chapter' : 'Add Chapter',
            style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.3), width: 2),
                      image: _imageFile != null ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) : null,
                    ),
                    child: _imageFile != null
                        ? null
                        : (existingThumbnail != null && existingThumbnail.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network('$apiBaseUrl/media/$existingThumbnail', fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imgPlaceholder()),
                                    Container(color: Colors.black.withOpacity(0.3)),
                                    const Center(child: Icon(Icons.edit_rounded, color: Colors.white, size: 28)),
                                  ],
                                ),
                              )
                            : _imgPlaceholder()),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _chapterNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Chapter Number',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Chapter Title',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: const Text('Is Free Chapter?', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Free chapters can be viewed without purchasing'),
                  value: _isFree,
                  activeColor: const Color(0xFF16A34A),
                  onChanged: (val) => setState(() => _isFree = val),
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isEditing ? 'Save Changes' : 'Create Chapter', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_rounded, size: 36, color: const Color(0xFF16A34A).withOpacity(0.5)),
          const SizedBox(height: 4),
          Text('Upload Chapter Image', style: TextStyle(color: const Color(0xFF16A34A).withOpacity(0.7), fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      );
}
