import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../models/payment_model.dart';
import '../../../services/payment_service.dart';
import 'success_screen.dart';
import 'failure_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final PaymentModel payment;

  const ProcessingScreen({super.key, required this.payment});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  Timer? _pollingTimer;
  WebViewController? _webViewController;
  bool _showWebview = false;

  @override
  void initState() {
    super.initState();
    
    // If the payment needs external authorization via WebView (e.g. Card)
    if (widget.payment.authUrl != null && widget.payment.authUrl!.isNotEmpty) {
      _showWebview = true;
      _initWebView();
    }
    
    // Start polling the backend for state changes
    _startPolling();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // If returning to our custom URL or webhooks, we can intercept
            if (request.url.contains('ethioclass://')) {
              setState(() => _showWebview = false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.payment.authUrl!));
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      final status = await PaymentService.checkPaymentStatus(widget.payment.txRef);
      
      if (!mounted) return;

      if (status == PaymentStatus.success) {
        _pollingTimer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SuccessScreen(txRef: widget.payment.txRef)),
        );
      } else if (status == PaymentStatus.failed || status == PaymentStatus.cancelled || status == PaymentStatus.expired) {
        _pollingTimer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FailureScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showWebview && _webViewController != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Complete Payment', style: TextStyle(color: Colors.white, fontSize: 16)),
          backgroundColor: const Color(0xFF0F172A),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // Canceling the flow
              setState(() => _showWebview = false);
            },
          ),
        ),
        body: WebViewWidget(controller: _webViewController!),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF2563EB)),
              const SizedBox(height: 30),
              const Text(
                'Processing payment',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please wait while we securely\nverify your payment.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 40),
              if (!_showWebview && widget.payment.authUrl != null) ...[
                // If the user closed the webview but the status is still pending, give them a chance to reopen
                TextButton(
                  onPressed: () => setState(() => _showWebview = true),
                  child: const Text('Resume Payment Provider', style: TextStyle(color: Color(0xFF2563EB))),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
