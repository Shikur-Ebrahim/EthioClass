// Payment service for Chapa integration

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PaymentService {
  // Backend API URL - points to your VPS
  static const String baseUrl = 'https://api.ethioclass.com/payments';

  /// Initializes a payment for the given course and returns the checkout URL and transaction reference.
  static Future<Map<String, String>> initializePayment(String courseId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/initialize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'course_id': courseId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'tx_ref': data['tx_ref'],
          'checkout_url': data['checkout_url'],
        };
      } else {
        throw Exception('Failed to initialize payment: ${response.body}');
      }
    } catch (e) {
      print('Payment Initialization Error: $e');
      throw Exception('Could not connect to payment server. Check your internet connection.');
    }
  }

  /// Verifies a payment with the given transaction reference.
  /// Returns true if successful, false otherwise.
  static Future<bool> verifyPayment(String txRef) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/verify/$txRef'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Payment Verification Error: $e');
      return false;
    }
  }

  /// Helper to launch the Chapa checkout URL
  static Future<void> launchCheckout(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch payment page');
    }
  }
}
