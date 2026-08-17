import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../core/theme.dart';
import '../../config/api_config.dart';
import '../../models/category_model.dart';
import '../../services/course_service.dart';
import 'edit_category_screen.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  File? _imageFile;
  bool _isSubmitting = false;
  bool _isLoadingList = false;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingList = true);
    try {
      final cats = await CourseService().getCategories();
      if (mounted) setState(() { _categories = cats; _isLoadingList = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingList = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 1080,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      _showSnack('Please select a banner image', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final uri = Uri.parse('$apiBaseUrl/admin/categories');
      final request = http.MultipartRequest('POST', uri);
      request.fields['name'] = _nameController.text.trim();
      request.fields['description'] = _descController.text.trim();

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

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        _showSnack('Category created successfully!');
        // Clear form
        _nameController.clear();
        _descController.clear();
        setState(() => _imageFile = null);
        // Refresh list
        _loadCategories();
      } else {
        _showSnack('Failed to create category: ${response.body}', isError: true);
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteCategory(Category cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Category'),
        content: Text('Delete "${cat.name}"? This cannot be undone.'),
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
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/admin/categories/${cat.id}'),
      );
      if (response.statusCode == 200) {
        _showSnack('Category deleted');
        _loadCategories();
      } else {
        _showSnack('Failed to delete', isError: true);
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<void> _editCategory(Category cat) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditCategoryScreen(category: cat)),
    );
    if (result == true) _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: const Text(
          'Manage Categories',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── ADD CATEGORY FORM ──────────────────────────────
            Container(
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
                    const Text(
                      'Add New Category',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 16),

                    // Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                          image: _imageFile != null
                              ? DecorationImage(
                                  image: FileImage(_imageFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _imageFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded,
                                      size: 40, color: AppColors.primary.withOpacity(0.5)),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tap to upload banner image',
                                    style: TextStyle(color: AppColors.primary.withOpacity(0.7), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Category Name',
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
                        labelText: 'Description',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Create Category',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),

            // ── EXISTING CATEGORIES LIST ─────────────────────
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Existing Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
                if (_isLoadingList)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (!_isLoadingList && _categories.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No categories yet.', style: TextStyle(color: AppColors.grey)),
                ),
              ),

            ..._categories.map((cat) => _CategoryTile(
              category: cat,
              onEdit: () => _editCategory(cat),
              onDelete: () => _deleteCategory(cat),
            )),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── CATEGORY TILE ────────────────────────────────────────────────────────────
class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({required this.category, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
            child: SizedBox(
              width: 72,
              height: 72,
              child: category.imageUrl != null && category.imageUrl!.isNotEmpty
                  ? Image.network(
                      category.imageUrl!,
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
                  Text(category.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(category.description,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20), onPressed: onEdit),
              IconButton(icon: const Icon(Icons.delete_rounded, color: AppColors.error, size: 20), onPressed: onDelete),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: const Icon(Icons.category_rounded, color: AppColors.primary),
    );
  }
}
