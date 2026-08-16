import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../services/payment_service.dart';

class PaymentWebviewScreen extends StatefulWidget {
  final String courseId;

  const PaymentWebviewScreen({
    super.key,
    required this.courseId,
  });

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;
  bool _isInitializing = true;
  String? _txRef;
  Timer? _timer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white);

    _initPayment();
  }

  Future<void> _initPayment() async {
    try {
      final result = await PaymentService.initializePayment(widget.courseId);
      final checkoutUrl = result['checkout_url']!;
      _txRef = result['tx_ref']!;
      
      _controller.loadRequest(Uri.parse(checkoutUrl));
      
      setState(() {
        _isInitializing = false;
      });

      // Poll every 4 seconds to check payment success
      _timer = Timer.periodic(const Duration(seconds: 4), (_) => _verifyPayment());
    } catch (e) {
      if (mounted) {
        Navigator.pop(context, false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _verifyPayment() async {
    if (_isChecking || _txRef == null) return;
    _isChecking = true;
    final bool isSuccess = await PaymentService.verifyPayment(_txRef!);
    if (isSuccess && mounted) {
      _timer?.cancel();
      Navigator.pop(context, true); // Return true = success
    }
    _isChecking = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Complete Payment',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  'Secured by Chapa',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_isInitializing) WebViewWidget(controller: _controller),
          if (_isInitializing)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Connecting to payment server...',
                      style: TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
