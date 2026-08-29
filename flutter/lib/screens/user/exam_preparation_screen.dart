import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme.dart';
import '../../models/chapter_model.dart';
import '../../config/api_config.dart';
import 'dart:async';
import 'package:flutter_markdown/flutter_markdown.dart';

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

            return ResultQuestionCard(
              index: index,
              question: q,
              userAnswer: userAnswer,
              correctAnswer: correctAnswer,
              userAnswerText: userAnswerText,
              correctAnswerText: correctAnswerText,
              isCorrect: isCorrect,
            );
          }),
        ],
      ),
    );
  }
}

class ResultQuestionCard extends StatefulWidget {
  final int index;
  final dynamic question;
  final String? userAnswer;
  final String correctAnswer;
  final String userAnswerText;
  final String correctAnswerText;
  final bool isCorrect;

  const ResultQuestionCard({
    super.key,
    required this.index,
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.userAnswerText,
    required this.correctAnswerText,
    required this.isCorrect,
  });

  @override
  State<ResultQuestionCard> createState() => _ResultQuestionCardState();
}

class _ResultQuestionCardState extends State<ResultQuestionCard> {
  bool _isExplaining = false;
  bool _isLoadingExplanation = false;
  bool _isFirstTimeExplaining = true;
  String? _explanation;
  String? _error;

  Future<void> _fetchExplanation() async {
    if (_explanation != null) return; // Already fetched
    
    setState(() {
      _isExplaining = true;
      _isLoadingExplanation = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/exam/explain'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'question': widget.question['question_text'],
          'answer': widget.correctAnswerText,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('error')) {
          final errMsg = data['error'] as String;
          if (mounted) {
            setState(() {
              if (errMsg == 'daily_limit_reached') {
                _error = 'The AI reached its daily limit. Please try again tomorrow! 🙏';
              } else {
                _error = 'AI Error: $errMsg';
              }
              _isLoadingExplanation = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _explanation = data['explanation'] ?? 'No explanation provided.';
              _isLoadingExplanation = false;
            });
          }
        }
      } else if (response.statusCode == 429) {
        if (mounted) {
          setState(() {
            _error = 'The AI reached its daily limit. Please try again tomorrow! 🙏';
            _isLoadingExplanation = false;
          });
        }
      } else {
        final data = jsonDecode(response.body);
        final msg = data['error'] ?? 'Unknown error from AI service.';
        if (mounted) {
          setState(() {
            _error = 'AI Error: $msg';
            _isLoadingExplanation = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not connect to AI service. Please try again next time!';
          _isLoadingExplanation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.isCorrect ? Colors.green.shade300 : Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, 
                   color: widget.isCorrect ? Colors.green : Colors.red, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Q${widget.index + 1}: ${widget.question['question_text']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Your Answer: ${widget.userAnswerText}', 
               style: TextStyle(color: widget.isCorrect ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w600)),
          if (!widget.isCorrect) ...[
            const SizedBox(height: 4),
            Text('Correct Answer: ${widget.correctAnswerText}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 16),
          
          if (!_isExplaining)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () {
                  if (_explanation != null) {
                    setState(() {
                      _isExplaining = true;
                      _isFirstTimeExplaining = false; 
                    });
                  } else {
                    _fetchExplanation();
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'EA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Ask AI to Explain', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6), // Soft gray/blue background
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFF1F5F9).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'EA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'EthioClass AI Teacher',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingExplanation)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                          ),
                          const SizedBox(width: 12),
                          Text('Analyzing the question...', style: TextStyle(color: AppColors.textMedium, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    )
                  else if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13))),
                        ],
                      ),
                    )
                  else
                    TypewriterMarkdown(text: _explanation!, animate: _isFirstTimeExplaining),
                    
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      onPressed: () => setState(() => _isExplaining = false),
                      child: const Text('Hide Explanation', style: TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TypewriterMarkdown extends StatefulWidget {
  final String text;
  final bool animate;
  const TypewriterMarkdown({super.key, required this.text, this.animate = true});

  @override
  State<TypewriterMarkdown> createState() => _TypewriterMarkdownState();
}

class _TypewriterMarkdownState extends State<TypewriterMarkdown> {
  String _displayedText = '';
  int _currentIndex = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _isAnimating = true;
      _animateText();
    } else {
      _displayedText = widget.text;
    }
  }

  void _animateText() async {
    while (_currentIndex < widget.text.length && mounted) {
      int nextChunk = (_currentIndex + 3).clamp(0, widget.text.length);
      setState(() {
        _displayedText = widget.text.substring(0, nextChunk);
        _currentIndex = nextChunk;
      });
      await Future.delayed(const Duration(milliseconds: 15));
    }
    if (mounted) {
      setState(() => _isAnimating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: _displayedText + (_isAnimating ? ' 🔵' : ''),
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          fontSize: 14,
          height: 1.6,
          color: AppColors.textDark,
        ),
        strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }
}
