import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../core/theme.dart';
import '../../config/api_config.dart';
import '../../models/category_model.dart';
import '../../models/course_model.dart';
import '../../services/course_service.dart';
import 'manage_chapters_screen.dart';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  bool _isLoadingList = false;
  List<Category> _categories = [];
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingList = true);
    try {
      final cats = await CourseService().getCategories();
      final crs = await CourseService().getCourses();
      if (mounted) {
        setState(() {
          _categories = cats;
          _courses = crs;
          _isLoadingList = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingList = false);
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
        builder: (_) => _CourseFormScreen(
          categories: _categories,
          onSuccess: () {
            _loadInitialData();
          },
        ),
      ),
    );
  }

  void _openEditForm(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CourseFormScreen(
          categories: _categories,
          courseToEdit: course,
          onSuccess: () {
            _loadInitialData();
          },
        ),
      ),
    );
  }

  Future<void> _deleteCourse(Course crs) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Course'),
        content: Text('Delete "${crs.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
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
      final response = await http.delete(Uri.parse('$apiBaseUrl/admin/courses/${crs.id}'));
      if (response.statusCode == 200) {
        _showSnack('Course deleted');
        _loadInitialData();
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
        title: const Text('Manage Courses',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _openAddForm,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Course'),
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
      body: _isLoadingList
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))
          : _courses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_outlined, size: 60, color: AppColors.grey.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text('No courses yet', style: TextStyle(color: AppColors.grey, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _openAddForm,
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Course'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF16A34A),
                  onRefresh: _loadInitialData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _courses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _CourseTile(
                      course: _courses[i],
                      onManageChapters: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManageChaptersScreen(course: _courses[i]),
                          ),
                        );
                      },
                      onEdit: () => _openEditForm(_courses[i]),
                      onDelete: () => _deleteCourse(_courses[i]),
                    ),
                  ),
                ),
    );
  }
}

// ── COURSE FORM SCREEN (Add + Edit) ───────────────────────────────────────
class _CourseFormScreen extends StatefulWidget {
  final List<Category> categories;
  final Course? courseToEdit;
  final VoidCallback onSuccess;

  const _CourseFormScreen({
    required this.categories,
    this.courseToEdit,
    required this.onSuccess,
  });

  @override
  State<_CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends State<_CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _aboutTextController = TextEditingController();
  final _instructorNameController = TextEditingController();
  final _instructorPhoneController = TextEditingController();

  final List<TextEditingController> _bulletControllers = [];

  File? _imageFile;
  bool _isSubmitting = false;
  Category? _selectedCategory;

  bool get _isEditing => widget.courseToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.courseToEdit!;
      _titleController.text = c.title;
      _descController.text = c.description;
      _aboutTextController.text = c.aboutText;
      _instructorNameController.text = c.instructorName;
      _instructorPhoneController.text = c.instructorPhone;

      // Pre-select the matching category
      if (c.categoryId != null) {
        _selectedCategory = widget.categories
            .where((cat) => cat.id == c.categoryId)
            .firstOrNull;
      }

      // Pre-fill bullet points
      for (final bullet in c.aboutBullets) {
        _bulletControllers.add(TextEditingController(text: bullet));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _aboutTextController.dispose();
    _instructorNameController.dispose();
    _instructorPhoneController.dispose();
    for (var c in _bulletControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60, maxWidth: 1080);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  void _addBulletField() {
    setState(() => _bulletControllers.add(TextEditingController()));
  }

  void _removeBulletField(int index) {
    setState(() {
      _bulletControllers[index].dispose();
      _bulletControllers.removeAt(index);
    });
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
    if (_selectedCategory == null) {
      _showSnack('Please select a category first', isError: true);
      return;
    }
    if (!_isEditing && _imageFile == null) {
      _showSnack('Please select a banner image', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final uri = _isEditing
          ? Uri.parse('$apiBaseUrl/admin/courses/${widget.courseToEdit!.id}')
          : Uri.parse('$apiBaseUrl/admin/courses');

      final request = http.MultipartRequest(_isEditing ? 'PUT' : 'POST', uri);

      request.fields['category_id'] = _selectedCategory!.id;
      request.fields['title'] = _titleController.text.trim();
      request.fields['description'] = _descController.text.trim();
      request.fields['about_text'] = _aboutTextController.text.trim();
      request.fields['instructor_name'] = _instructorNameController.text.trim();
      request.fields['instructor_phone'] = _instructorPhoneController.text.trim();

      final bullets = _bulletControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      request.fields['about_bullets'] = jsonEncode(bullets);

      if (_imageFile != null) {
        final mimeTypeData = lookupMimeType(_imageFile!.path)?.split('/');
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _imageFile!.path,
            contentType: mimeTypeData != null
                ? MediaType(mimeTypeData[0], mimeTypeData[1])
                : MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnack(_isEditing ? 'Course updated successfully!' : 'Course created successfully!');
        widget.onSuccess();
        if (mounted) Navigator.pop(context);
      } else {
        _showSnack(
          'Failed to ${_isEditing ? 'update' : 'create'} course: ${response.body}',
          isError: true,
        );
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingThumbnail = widget.courseToEdit?.thumbnailUrl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text(
          _isEditing ? 'Edit Course' : 'Add New Course',
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category Dropdown
                DropdownButtonFormField<Category>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Select Category',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: widget.categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                  validator: (val) => val == null ? 'Please select a category' : null,
                ),
                const SizedBox(height: 14),

                // Image Picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.3), width: 2),
                      image: _imageFile != null
                          ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                          : (existingThumbnail != null && existingThumbnail.isNotEmpty
                              ? null
                              : null),
                    ),
                    child: _imageFile != null
                        ? null
                        : (existingThumbnail != null && existingThumbnail.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      '$apiBaseUrl/media/$existingThumbnail',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                                    ),
                                    Container(
                                      color: Colors.black.withOpacity(0.35),
                                      child: const Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.edit_rounded, color: Colors.white, size: 28),
                                            SizedBox(height: 4),
                                            Text('Tap to change image',
                                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _imagePlaceholder()),
                  ),
                ),
                const SizedBox(height: 14),

                // Course Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Course Title',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // Short Description
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Short Description',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                // About Text
                TextFormField(
                  controller: _aboutTextController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'About Course (Full text)',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // Bullet Points
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bullet Points',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    TextButton.icon(
                      onPressed: _addBulletField,
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Add Point'),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF16A34A)),
                    )
                  ],
                ),
                ..._bulletControllers.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: 'e.g. Covers all Grade 12 chapters',
                              filled: true,
                              fillColor: AppColors.background,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: AppColors.error),
                          onPressed: () => _removeBulletField(idx),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),
                const Text('Instructor Details',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _instructorNameController,
                  decoration: InputDecoration(
                    labelText: 'Instructor Name',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _instructorPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Instructor Phone Number',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
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
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Create Course',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded,
            size: 40, color: const Color(0xFF16A34A).withOpacity(0.5)),
        const SizedBox(height: 6),
        Text(
          'Tap to upload course banner',
          style: TextStyle(color: const Color(0xFF16A34A).withOpacity(0.7), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ── COURSE TILE ────────────────────────────────────────────────────────────
class _CourseTile extends StatelessWidget {
  final Course course;
  final VoidCallback onManageChapters;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CourseTile({required this.course, required this.onManageChapters, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
            child: SizedBox(
              width: 72,
              height: 72,
              child: course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
                  ? Image.network(
                      '$apiBaseUrl/media/${course.thumbnailUrl!}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    )
                  : _fallback(),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(course.description,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.list_alt_rounded, color: Color(0xFF2563EB), size: 22),
                tooltip: 'Manage Chapters',
                onPressed: onManageChapters,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: Color(0xFF16A34A), size: 20),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFF16A34A).withOpacity(0.1),
      child: const Icon(Icons.menu_book_rounded, color: Color(0xFF16A34A)),
    );
  }
}
