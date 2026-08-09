import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'config/api_config.dart';

void main() {
  runApp(const EthioClassApp());
}

class EthioClassApp extends StatelessWidget {
  const EthioClassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EthioClass',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A56DB)),
        useMaterial3: true,
      ),
      home: const HealthCheckPage(),
    );
  }
}

/// Temporary infrastructure test page.
/// Verifies connectivity to https://api.ethioclass.com
/// This screen will be replaced by the real app UI in future phases.
class HealthCheckPage extends StatefulWidget {
  const HealthCheckPage({super.key});

  @override
  State<HealthCheckPage> createState() => _HealthCheckPageState();
}

class _HealthCheckPageState extends State<HealthCheckPage> {
  String _status = 'Checking...';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _runHealthCheck();
  }

  Future<void> _runHealthCheck() async {
    debugPrint('[EthioClass] Calling $apiBaseUrl/health');
    try {
      final result = await ApiService().healthCheck();
      final status = result['status'] as String? ?? 'unknown';
      debugPrint('[EthioClass] Health response: $result');
      setState(() {
        _status = 'Backend OK: $status';
        _loading = false;
      });
    } catch (e) {
      debugPrint('[EthioClass] Health check error: $e');
      setState(() {
        _status = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'EthioClass',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              apiBaseUrl,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 40),
            if (_loading)
              const CircularProgressIndicator(color: Color(0xFF1A56DB))
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _status.startsWith('Backend OK')
                      ? const Color(0xFF065F46)
                      : const Color(0xFF7F1D1D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            if (!_loading)
              TextButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _status = 'Checking...';
                  });
                  _runHealthCheck();
                },
                child: const Text('Retry', style: TextStyle(color: Color(0xFF1A56DB))),
              ),
          ],
        ),
      ),
    );
  }
}
