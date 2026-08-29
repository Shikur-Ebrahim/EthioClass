import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme.dart';
import '../../models/chapter_model.dart';
import '../../config/api_config.dart';
import 'dart:async';

class ExamPreparationScreen extends StatefulWidget {
  final Chapter chapter;
  const ExamPreparationScreen({super.key, required this.chapter});

  @override
  State<ExamPreparationScreen> createState() => _ExamPreparationScreenState();
}

class _ExamPreparationScreenState extends State<ExamPreparationScreen> {
  bool _isLoading = true;
  List<dynamic> _questions = [];
  int _currentIndex = 0;
  String? _selectedOption;
  final List<String?> _userAnswers = [];
  int _score = 0;
  bool _isFinished = false;
  
  Timer? _timer;
  int _timeLeft = 60; // default

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/chapters/${widget.chapter.id}/exam'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _questions = data;
            _isLoading = false;
            if (_questions.isNotEmpty) {
               _startTimerForCurrent();
            } else {
               _isFinished = true;
            }
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startTimerForCurrent() {
    _timer?.cancel();
    _timeLeft = _questions[_currentIndex]['time_limit_seconds'] ?? 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
          } else {
             _timer?.cancel();
             _nextQuestion(); // Time's up
          }
        });
      }
    });
  }

  void _nextQuestion() {
    _userAnswers.add(_selectedOption);
    if (_selectedOption != null) {
      if (_selectedOption == _questions[_currentIndex]['correct_option']) {
        _score++;
      }
    }
    
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
      });
      _startTimerForCurrent();
    } else {
      setState(() {
        _isFinished = true;
      });
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_isFinished) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
           backgroundColor: Colors.white,
           elevation: 0,
           iconTheme: const IconThemeData(color: AppColors.textDark),
           title: const Text('Exam Result', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events_rounded, size: 64, color: Colors.amber),
                  const SizedBox(height: 16),
                  Text('You scored $_score out of ${_questions.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)
                    ),
                    child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Review Answers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 16),
            ...List.generate(_questions.length, (index) {
              final q = _questions[index];
              final userAnswer = _userAnswers.length > index ? _userAnswers[index] : null;
              final correctAnswer = q['correct_option'];
              final isCorrect = userAnswer == correctAnswer;
              final explanation = q['explanation'] ?? '';

              String getOptionText(String? option) {
                if (option == 'A') return q['option_a'];
                if (option == 'B') return q['option_b'];
                if (option == 'C') return q['option_c'];
                if (option == 'D') return q['option_d'];
                return '';
              }

              final userAnswerText = userAnswer != null ? '$userAnswer: ${getOptionText(userAnswer)}' : 'Not answered';
              final correctAnswerText = '$correctAnswer: ${getOptionText(correctAnswer)}';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isCorrect ? Colors.green.shade300 : Colors.red.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, 
                             color: isCorrect ? Colors.green : Colors.red, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Q${index + 1}: ${q['question_text']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Your Answer: $userAnswerText', 
                         style: TextStyle(color: isCorrect ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w600)),
                    if (!isCorrect) ...[
                      const SizedBox(height: 4),
                      Text('Correct Answer: $correctAnswerText', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                    if (!isCorrect && explanation.toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(explanation, style: const TextStyle(color: AppColors.textDark, fontSize: 13))),
                          ],
                        ),
                      )
                    ]
                  ],
                ),
              );
            }),
          ],
        )
      );
    }

    final q = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text('${widget.chapter.title} Exam', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('$_timeLeft s', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             Text('Question ${_currentIndex + 1} of ${_questions.length}', style: const TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.bold)),
             const SizedBox(height: 12),
             Text(q['question_text'], style: const TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 24),
             _buildOption('A', q['option_a']),
             const SizedBox(height: 12),
             _buildOption('B', q['option_b']),
             const SizedBox(height: 12),
             _buildOption('C', q['option_c']),
             const SizedBox(height: 12),
             _buildOption('D', q['option_d']),
             const Spacer(),
             ElevatedButton(
               onPressed: _selectedOption == null ? null : _nextQuestion,
               style: ElevatedButton.styleFrom(
                 backgroundColor: AppColors.primary,
                 padding: const EdgeInsets.symmetric(vertical: 16),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
               ),
               child: Text(_currentIndex == _questions.length - 1 ? 'Finish Exam' : 'Next Question', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
             )
          ],
        )
      )
    );
  }

  Widget _buildOption(String id, String text) {
    bool isSelected = _selectedOption == id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedOption = id);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.greyLight, width: 2),
        ),
        child: Row(
          children: [
             Container(
               width: 32, height: 32,
               decoration: BoxDecoration(
                 color: isSelected ? AppColors.primary : AppColors.greyLight,
                 shape: BoxShape.circle,
               ),
               child: Center(child: Text(id, style: TextStyle(color: isSelected ? Colors.white : AppColors.textDark, fontWeight: FontWeight.bold))),
             ),
             const SizedBox(width: 12),
             Expanded(child: Text(text, style: const TextStyle(color: AppColors.textDark, fontSize: 15))),
          ],
        )
      )
    );
  }
}
