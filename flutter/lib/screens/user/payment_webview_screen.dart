import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../services/payment_service.dart';

class PaymentWebviewScreen extends StatefulWidget {
  final String checkoutUrl;
  final String txRef;

  const PaymentWebviewScreen({
    super.key,
    required this.checkoutUrl,
    required this.txRef,
  });

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  Timer? _timer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));

    // Poll for payment success
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      _verifyPayment();
    });
  }

  Future<void> _verifyPayment() async {
    if (_isChecking) return;
    _isChecking = true;

    bool isSuccess = await PaymentService.verifyPayment(widget.txRef);
    if (isSuccess) {
      _timer?.cancel();
      if (mounted) {
        Navigator.pop(context, true); // Return true indicating success
      }
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
        title: const Text('Complete Payment', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context, false); // Return false indicating cancellation
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
