import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../services/payment_service.dart';

class PaymentWebviewScreen extends StatefulWidget {
  final String courseId;
  final String checkoutUrl;
  final String txRef;

  const PaymentWebviewScreen({
    super.key,
    required this.courseId,
    required this.checkoutUrl,
    required this.txRef,
  });

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;
  Timer? _timer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..loadRequest(Uri.parse(widget.checkoutUrl));

    // Poll every 4 seconds to check payment success
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _verifyPayment());
  }

  Future<void> _verifyPayment() async {
    if (_isChecking) return;
    _isChecking = true;
    final bool isSuccess = await PaymentService.verifyPayment(widget.txRef);
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
          WebViewWidget(controller: _controller),
        ],
      ),
    );
  }
}
