import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
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
        if (mounted) {
          setState(() {
            _explanation = data['explanation'] ?? 'No explanation provided.';
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load explanation');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'The AI reached its daily limit or encountered an error. Please try again next time!';
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 16),
              const Text(
                'AI Teacher Explanation',
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
                    CircularProgressIndicator(color: Colors.blue),
                    SizedBox(height: 16),
                    Text('Analyzing the question...', style: TextStyle(color: AppColors.textMedium)),
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
                  Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600))),
                ],
              ),
            )
          else
            Text(
              _explanation,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppColors.textDark,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Got it!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
