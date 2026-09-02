import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme.dart';
import '../../models/chapter_model.dart';
import '../../config/api_config.dart';
import '../../widgets/ethioclass_loading.dart';

class ManageExamScreen extends StatefulWidget {
  final Chapter chapter;
  const ManageExamScreen({super.key, required this.chapter});

  @override
  State<ManageExamScreen> createState() => _ManageExamScreenState();
}

class _ManageExamScreenState extends State<ManageExamScreen> {
  bool _isLoading = true;
  List<dynamic> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('$apiBaseUrl/admin/chapters/${widget.chapter.id}/exam'));
      if (res.statusCode == 200) {
        setState(() => _questions = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteQuestion(String id) async {
    try {
      await http.delete(Uri.parse('$apiBaseUrl/admin/exam/questions/$id'));
      _loadQuestions();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _openForm([dynamic question]) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _ExamQuestionForm(
        chapterId: widget.chapter.id,
        questionToEdit: question,
        onSuccess: _loadQuestions,
      )
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: const Text('Manage Exam', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Question'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: EthioClassLoading())
          : _questions.isEmpty
              ? const Center(child: Text('No questions added yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final q = _questions[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                      child: Row(
                        children: [
                          Expanded(child: Text('${index + 1}. ${q['question_text']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _openForm(q)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteQuestion(q['id'])),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _ExamQuestionForm extends StatefulWidget {
  final String chapterId;
  final dynamic questionToEdit;
  final VoidCallback onSuccess;

  const _ExamQuestionForm({required this.chapterId, this.questionToEdit, required this.onSuccess});

  @override
  State<_ExamQuestionForm> createState() => _ExamQuestionFormState();
}

class _ExamQuestionFormState extends State<_ExamQuestionForm> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _aController = TextEditingController();
  final _bController = TextEditingController();
  final _cController = TextEditingController();
  final _dController = TextEditingController();
  final _timeController = TextEditingController(text: '60');
  String _correctOption = 'A';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.questionToEdit != null) {
      _questionController.text = widget.questionToEdit['question_text'];
      _aController.text = widget.questionToEdit['option_a'];
      _bController.text = widget.questionToEdit['option_b'];
      _cController.text = widget.questionToEdit['option_c'];
      _dController.text = widget.questionToEdit['option_d'];
      _timeController.text = widget.questionToEdit['time_limit_seconds'].toString();
      _correctOption = widget.questionToEdit['correct_option'];
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final payload = {
      'chapter_id': widget.chapterId,
      'question_text': _questionController.text,
      'option_a': _aController.text,
      'option_b': _bController.text,
      'option_c': _cController.text,
      'option_d': _dController.text,
      'correct_option': _correctOption,
      'time_limit_seconds': int.tryParse(_timeController.text) ?? 60,
    };

    try {
      if (widget.questionToEdit == null) {
        await http.post(Uri.parse('$apiBaseUrl/admin/chapters/${widget.chapterId}/exam'),
            body: jsonEncode(payload), headers: {'Content-Type': 'application/json'});
      } else {
        await http.put(Uri.parse('$apiBaseUrl/admin/exam/questions/${widget.questionToEdit['id']}'),
            body: jsonEncode(payload), headers: {'Content-Type': 'application/json'});
      }
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.questionToEdit == null ? 'Add Question' : 'Edit Question', style: const TextStyle(color: AppColors.textDark))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _questionController, decoration: const InputDecoration(labelText: 'Question'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _aController, decoration: const InputDecoration(labelText: 'Option A'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _bController, decoration: const InputDecoration(labelText: 'Option B'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _cController, decoration: const InputDecoration(labelText: 'Option C'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _dController, decoration: const InputDecoration(labelText: 'Option D'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _correctOption,
                decoration: const InputDecoration(labelText: 'Correct Option'),
                items: ['A', 'B', 'C', 'D'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _correctOption = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _timeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Time limit (seconds)'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving ? const CircularProgressIndicator() : const Text('Save Question'),
              )
            ],
          )
        )
      )
    );
  }
}
