import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../core/theme.dart';
import '../../models/lesson_model.dart';
import '../../widgets/ethioclass_loading.dart';

class ManageQuizScreen extends StatefulWidget {
  final Lesson lesson;
  const ManageQuizScreen({super.key, required this.lesson});

  @override
  State<ManageQuizScreen> createState() => _ManageQuizScreenState();
}

class _ManageQuizScreenState extends State<ManageQuizScreen> {
  List<Map<String, dynamic>> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
  }

  Future<void> _fetchQuizzes() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/quizzes?lesson_id=${widget.lesson.id}'));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _quizzes = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteQuiz(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Question?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final res = await http.delete(Uri.parse('$apiBaseUrl/admin/quizzes/$id'));
      if (res.statusCode == 200 && mounted) {
        _showSnack('Question deleted', isError: false);
        _fetchQuizzes();
      }
    } catch (_) {
      _showSnack('Failed to delete question');
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }

  void _openQuizForm({Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuizFormSheet(
        lessonId: widget.lesson.id,
        existing: existing,
        onSaved: () {
          Navigator.pop(context);
          _fetchQuizzes();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quiz Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            Text('${widget.lesson.title}', style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _openQuizForm(),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: EthioClassLoading())
          : _quizzes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.quiz_outlined, size: 64, color: AppColors.grey.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text('No questions yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
                      const SizedBox(height: 8),
                      const Text('Tap "Add Question" to get started', style: TextStyle(fontSize: 13, color: AppColors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _openQuizForm(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add First Question'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _quizzes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final q = _quizzes[i];
                    return _QuizCard(
                      index: i,
                      quiz: q,
                      onEdit: () => _openQuizForm(existing: q),
                      onDelete: () => _deleteQuiz(q['id']),
                    );
                  },
                ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> quiz;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuizCard({required this.index, required this.quiz, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final options = ['A', 'B', 'C', 'D'];
    final optionValues = {
      'A': quiz['option_a'] ?? '',
      'B': quiz['option_b'] ?? '',
      'C': quiz['option_c'] ?? '',
      'D': quiz['option_d'] ?? '',
    };
    final correct = quiz['correct_answer'] ?? '';
    final explanation = quiz['explanation'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
                child: Center(child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(quiz['question'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark))),
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary)),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_rounded, size: 18, color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 12),
          ...options.map((opt) {
            final isCorrect = opt == correct;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCorrect ? AppColors.success.withOpacity(0.1) : AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isCorrect ? AppColors.success : AppColors.greyLight),
              ),
              child: Row(
                children: [
                  Text('$opt. ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: isCorrect ? AppColors.success : AppColors.textMedium)),
                  Expanded(child: Text(optionValues[opt] ?? '', style: TextStyle(fontSize: 12, color: isCorrect ? AppColors.success : AppColors.textDark))),
                  if (isCorrect) const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                ],
              ),
            );
          }),
          if (explanation != null && explanation.toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
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
                  Expanded(child: Text(explanation.toString(), style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), height: 1.4))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuizFormSheet extends StatefulWidget {
  final String lessonId;
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;

  const _QuizFormSheet({required this.lessonId, this.existing, required this.onSaved});

  @override
  State<_QuizFormSheet> createState() => _QuizFormSheetState();
}

class _QuizFormSheetState extends State<_QuizFormSheet> {
  final _questionCtrl = TextEditingController();
  final _optionACtrl = TextEditingController();
  final _optionBCtrl = TextEditingController();
  final _optionCCtrl = TextEditingController();
  final _optionDCtrl = TextEditingController();
  String _correctAnswer = 'A';
  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final q = widget.existing!;
      _questionCtrl.text = q['question'] ?? '';
      _optionACtrl.text = q['option_a'] ?? '';
      _optionBCtrl.text = q['option_b'] ?? '';
      _optionCCtrl.text = q['option_c'] ?? '';
      _optionDCtrl.text = q['option_d'] ?? '';
      _correctAnswer = q['correct_answer'] ?? 'A';
    }
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _optionACtrl.dispose();
    _optionBCtrl.dispose();
    _optionCCtrl.dispose();
    _optionDCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_questionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question is required'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    final body = jsonEncode({
      'lesson_id': widget.lessonId,
      'question': _questionCtrl.text.trim(),
      'option_a': _optionACtrl.text.trim(),
      'option_b': _optionBCtrl.text.trim(),
      'option_c': _optionCCtrl.text.trim(),
      'option_d': _optionDCtrl.text.trim(),
      'correct_answer': _correctAnswer,
    });

    try {
      final http.Response res;
      if (_isEditing) {
        res = await http.put(
          Uri.parse('$apiBaseUrl/admin/quizzes/${widget.existing!['id']}'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
      } else {
        res = await http.post(
          Uri.parse('$apiBaseUrl/admin/quizzes'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        );
      }

      if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
        widget.onSaved();
      } else if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${res.body}'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _buildField(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.greyLight, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(_isEditing ? 'Edit Question' : 'Add Question',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 20),

            _buildField('Question *', _questionCtrl, maxLines: 3),
            _buildField('Option A', _optionACtrl),
            _buildField('Option B', _optionBCtrl),
            _buildField('Option C', _optionCCtrl),
            _buildField('Option D', _optionDCtrl),

            // Correct Answer Selector
            const Text('Correct Answer *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
            const SizedBox(height: 6),
            Row(
              children: ['A', 'B', 'C', 'D'].map((opt) {
                final isSelected = _correctAnswer == opt;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _correctAnswer = opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.success : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? AppColors.success : AppColors.greyLight),
                      ),
                      child: Center(
                        child: Text(opt, style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : AppColors.textMedium,
                            fontSize: 14)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // AI handles explanation automatically
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('EthioClass AI will automatically generate and save the explanation when a student first asks.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), height: 1.4)),
                  ),
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? 'Update Question' : 'Save Question',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
