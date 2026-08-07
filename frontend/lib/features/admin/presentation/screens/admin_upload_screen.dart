import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../student/presentation/screens/course_details_screen.dart'; // For CourseColors

class AdminUploadScreen extends ConsumerStatefulWidget {
  const AdminUploadScreen({super.key});

  @override
  ConsumerState<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends ConsumerState<AdminUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  String _courseTitle = '';
  String _instructorName = '';
  String _description = '';
  String _category = 'Grade 12';
  bool _isUploading = false;

  final List<String> _categories = ['Grade 9', 'Grade 10', 'Grade 11', 'Grade 12', 'TVET', 'University Prep'];
  
  // Modules data structure
  final List<Map<String, dynamic>> _modules = [
    {'title': '', 'videoFile': null, 'pdfFile': null}
  ];

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
        title: const Text('Create New Course', style: TextStyle(color: CourseColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _isUploading
          ? _buildUploadingState()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _SectionTitle(title: 'Course Details'),
                  _buildTextField(
                    label: 'Course Title',
                    hint: 'e.g. Advanced Mathematics',
                    onSaved: (val) => _courseTitle = val ?? '',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Instructor Name',
                    hint: 'e.g. Abebe Kebede',
                    onSaved: (val) => _instructorName = val ?? '',
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Description',
                    hint: 'What will students learn?',
                    maxLines: 4,
                    onSaved: (val) => _description = val ?? '',
                  ),
                  const SizedBox(height: 24),
                  
                  _SectionTitle(title: 'Course Thumbnail'),
                  _buildFilePicker(
                    label: 'Upload Thumbnail Image',
                    icon: Icons.image_outlined,
                    color: CourseColors.primaryBlue,
                    onTap: () {
                      // Implement file picker logic for image
                    }
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle(title: 'Curriculum & Videos'),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _modules.add({'title': '', 'videoFile': null, 'pdfFile': null});
                          });
                        },
                        icon: const Icon(Icons.add, color: CourseColors.yellow, size: 18),
                        label: const Text('Add Module', style: TextStyle(color: CourseColors.yellow)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  ...List.generate(_modules.length, (index) => _buildModuleCard(index)),
                  
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CourseColors.yellow,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Publish Course to Cloudflare R2', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildUploadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: CourseColors.yellow),
          const SizedBox(height: 24),
          const Text('Uploading to Cloudflare R2...', style: TextStyle(color: CourseColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Uploading videos and saving to database.', style: TextStyle(color: CourseColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required String hint, int maxLines = 1, required FormFieldSetter<String> onSaved}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          style: const TextStyle(color: CourseColors.textPrimary),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: CourseColors.textSecondary.withOpacity(0.5)),
            filled: true,
            fillColor: CourseColors.cardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: CourseColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: CourseColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: CourseColors.yellow)),
          ),
          validator: (value) => value == null || value.isEmpty ? 'Required' : null,
          onSaved: onSaved,
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: TextStyle(color: CourseColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _category,
          dropdownColor: CourseColors.cardBg,
          style: const TextStyle(color: CourseColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: CourseColors.cardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: CourseColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: CourseColors.border)),
          ),
          items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _category = val);
          },
        ),
      ],
    );
  }

  Widget _buildFilePicker({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: CourseColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CourseColors.border, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: CourseColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text('Tap to browse files', style: TextStyle(color: CourseColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CourseColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CourseColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Module ${index + 1}', style: const TextStyle(color: CourseColors.yellow, fontSize: 16, fontWeight: FontWeight.bold)),
              if (_modules.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => setState(() => _modules.removeAt(index)),
                )
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            style: const TextStyle(color: CourseColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Video Title (e.g. Introduction to Physics)',
              hintStyle: TextStyle(color: CourseColors.textSecondary.withOpacity(0.5)),
              filled: true,
              fillColor: CourseColors.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onSaved: (val) => _modules[index]['title'] = val,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFilePicker(
                  label: 'Upload Video',
                  icon: Icons.video_file_outlined,
                  color: CourseColors.success,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilePicker(
                  label: 'Upload PDF Notes',
                  icon: Icons.picture_as_pdf_outlined,
                  color: const Color(0xFF8B5CF6),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isUploading = true;
      });
      // Simulate upload process to Cloudflare R2 and Supabase
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course uploaded successfully!'), backgroundColor: CourseColors.success),
        );
        Navigator.pop(context);
      });
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
