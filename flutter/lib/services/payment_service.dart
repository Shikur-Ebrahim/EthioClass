import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/payment_model.dart';

class PaymentService {
  static const String baseUrl = 'https://api.ethioclass.com/payments';

  /// Initiates a payment for the given course, using the specified payment method.
  static Future<PaymentModel> createPayment({
    required String courseId,
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'course_id': courseId,
          'payment_method': paymentMethod,
          if (phoneNumber != null && phoneNumber.isNotEmpty) 'phone_number': phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        return PaymentModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create payment: ${response.body}');
      }
    } catch (e) {
      debugPrint('Payment Creation Error: $e');
      throw Exception('Could not connect to payment server. Check your internet connection.');
    }
  }

  /// Polls the payment status from the EthioClass backend securely.
  static Future<PaymentStatus> checkPaymentStatus(String txRef) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$txRef/status'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return parsePaymentStatus(data['status']);
      }
      return PaymentStatus.unknown;
    } catch (e) {
      debugPrint('Payment Status Error: $e');
      return PaymentStatus.unknown;
    }
  }
}
