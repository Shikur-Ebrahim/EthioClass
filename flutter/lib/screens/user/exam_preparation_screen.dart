import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme.dart';
import '../../models/chapter_model.dart';
import '../../config/api_config.dart';
import 'dart:async';
import 'widgets/ai_explanation_sheet.dart';

class ExamPreparationScreen extends StatefulWidget {
  final Chapter chapter;
  const ExamPreparationScreen({super.key, required this.chapter});

  @override
  State<ExamPreparationScreen> createState() => _ExamPreparationScreenState();
}

class _ExamPreparationScreenState extends State<ExamPreparationScreen> {
  List<dynamic> _questions = [];
  bool _isLoading = true;
  int _score = 0;
  bool _isFinished = false;

  Timer? _timer;
  int _timeLeft = 0;

  List<String?> _userAnswers = [];
  int _unlockedIndex = 0; // Which question index is currently unlocked

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
               _userAnswers = List.filled(_questions.length, null, growable: true);
               _startGlobalTimer();
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

  void _startGlobalTimer() {
    _timer?.cancel();
    int totalTime = 0;
    for (var q in _questions) {
      totalTime += (q['time_limit_seconds'] as int? ?? 60);
    }
    _timeLeft = totalTime;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
          } else {
             _finishExam(); // Time's up
          }
        });
      }
    });
  }

  void _finishExam() {
    _timer?.cancel();
    _score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (i < _userAnswers.length && _userAnswers[i] != null && _userAnswers[i] == _questions[i]['correct_option']) {
        _score++;
      }
    }
    setState(() {
      _isFinished = true;
    });
  }

  void _onOptionSelected(int qIndex, String optionId) {
    setState(() {
      _userAnswers[qIndex] = optionId;
      if (_unlockedIndex == qIndex && qIndex < _questions.length - 1) {
        _unlockedIndex = qIndex + 1; // Unlock next question
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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

    if (_questions.isEmpty && !_isFinished) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textDark),
          title: Text('${widget.chapter.title} Exam', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: const Center(
          child: Text('No questions available for this exam.', style: TextStyle(color: AppColors.textMedium, fontSize: 16)),
        ),
      );
    }

    if (_isFinished) {
      return _buildResultScreen();
    }

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
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.error, size: 20),
                  const SizedBox(width: 4),
                  Text(_formatTime(_timeLeft), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _questions.length + 1, // +1 for the submit button
        itemBuilder: (context, index) {
          if (index == _questions.length) {
            // Submit button at the bottom
            final allAnswered = _unlockedIndex == _questions.length - 1 && _userAnswers.last != null;
            return Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              child: ElevatedButton(
                onPressed: allAnswered ? _finishExam : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit Exam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            );
          }

          final q = _questions[index];
          final isUnlocked = index <= _unlockedIndex;

          return Opacity(
            opacity: isUnlocked ? 1.0 : 0.4,
            child: IgnorePointer(
              ignoring: !isUnlocked,
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Question ${index + 1}', style: const TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(q['question_text'], style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _buildOption(index, 'A', q['option_a']),
                    const SizedBox(height: 12),
                    _buildOption(index, 'B', q['option_b']),
                    const SizedBox(height: 12),
                    _buildOption(index, 'C', q['option_c']),
                    const SizedBox(height: 12),
                    _buildOption(index, 'D', q['option_d']),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOption(int qIndex, String id, String text) {
    bool isSelected = _userAnswers[qIndex] == id;
    return GestureDetector(
      onTap: () => _onOptionSelected(qIndex, id),
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

  Widget _buildResultScreen() {
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
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.auto_awesome, color: Colors.blue, size: 18),
                      label: const Text('Ask AI to Explain', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AIExplanationSheet(
                            questionText: q['question_text'],
                            correctAnswerText: correctAnswerText,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      )
    );
  }
}
