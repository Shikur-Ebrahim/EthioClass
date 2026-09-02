import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../config/api_config.dart';
import '../../../core/theme.dart';

class AIExplanationSheet extends StatefulWidget {
  final String questionText;
  final String correctAnswerText;

  const AIExplanationSheet({
    super.key,
    required this.questionText,
    required this.correctAnswerText,
  });

  @override
  State<AIExplanationSheet> createState() => _AIExplanationSheetState();
}

class _AIExplanationSheetState extends State<AIExplanationSheet> {
  String _explanation = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchExplanation();
  }

  Future<void> _fetchExplanation() async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/exam/explain'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'question': widget.questionText,
          'answer': widget.correctAnswerText,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Check if backend returned an error field (e.g. Gemini error)
        if (data.containsKey('error')) {
          final errMsg = data['error'] as String;
          if (mounted) {
            setState(() {
              if (errMsg == 'daily_limit_reached') {
                _error =
                    'The AI reached its daily limit. Please try again tomorrow! 🙏';
              } else {
                _error = 'AI Error: $errMsg';
              }
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _explanation = data['explanation'] ?? 'No explanation provided.';
              _isLoading = false;
            });
          }
        }
      } else if (response.statusCode == 429) {
        // Daily limit reached
        if (mounted) {
          setState(() {
            _error =
                'The AI reached its daily limit. Please try again tomorrow! 🙏';
            _isLoading = false;
          });
        }
      } else {
        // Show the actual error from backend for diagnosis
        final data = jsonDecode(response.body);
        final msg = data['error'] ?? 'Unknown error from AI service.';
        if (mounted) {
          setState(() {
            _error = 'AI Error: $msg';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'Could not connect to AI service. Please try again next time!';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2196F3),
                      Color(0xFF9C27B0),
                    ], // Blue to Purple
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'EA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'EthioClass AI Teacher',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        color: Colors.blue,
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'AI is analyzing your answer...',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Generating a tailored explanation',
                      style: TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: TypewriterMarkdown(text: _explanation),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TypewriterMarkdown extends StatefulWidget {
  final String text;
  const TypewriterMarkdown({super.key, required this.text});

  @override
  State<TypewriterMarkdown> createState() => _TypewriterMarkdownState();
}

class _TypewriterMarkdownState extends State<TypewriterMarkdown> {
  String _displayedText = '';
  int _currentIndex = 0;
  bool _isAnimating = true;

  @override
  void initState() {
    super.initState();
    _animateText();
  }

  void _animateText() async {
    while (_currentIndex < widget.text.length && mounted) {
      // Add a chunk of characters at a time for faster but smooth typing
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
      data:
          _displayedText +
          (_isAnimating ? ' 🔵' : ''), // Blinking cursor effect
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          fontSize: 15,
          height: 1.6,
          color: AppColors.textDark,
        ),
        strong: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}
