import 'package:flutter/material.dart';
import '../../../models/course_model.dart';
import '../../../services/payment_service.dart';
import 'processing_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Course course;

  const CheckoutScreen({super.key, required this.course});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedMethod = 'telebirr';
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, String>> _methods = [
    {'id': 'telebirr', 'name': 'Telebirr', 'icon': '📱'},
    {'id': 'cbebirr', 'name': 'CBE Birr', 'icon': '🏦'},
    {'id': 'awash', 'name': 'AwashBirr', 'icon': '🏦'},
    {'id': 'card', 'name': 'Card', 'icon': '💳'},
  ];

  Future<void> _processPayment() async {
    if (_selectedMethod != 'card' && _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final payment = await PaymentService.createPayment(
        courseId: widget.course.id,
        paymentMethod: _selectedMethod,
        phoneNumber: _phoneController.text.trim(),
      );

      if (!mounted) return;

      // Navigate to processing screen, where the state polling happens natively
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProcessingScreen(payment: payment),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Basic standard layout as requested
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Payment', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(widget.course.title, style: const TextStyle(color: Colors.white70))),
                        const Text('249 ETB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 30),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('249 ETB', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              const Text('Payment Method', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // Method selection
              ..._methods.map((method) => GestureDetector(
                onTap: () => setState(() => _selectedMethod = method['id']!),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _selectedMethod == method['id'] ? const Color(0xFF2563EB).withValues(alpha: 0.2) : const Color(0xFF1E293B),
                    border: Border.all(
                      color: _selectedMethod == method['id'] ? const Color(0xFF2563EB) : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(method['icon']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(method['name']!, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
                      if (_selectedMethod == method['id'])
                        const Icon(Icons.check_circle, color: Color(0xFF2563EB)),
                    ],
                  ),
                ),
              )),

              // Phone number input
              if (_selectedMethod != 'card') ...[
                const SizedBox(height: 20),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: const TextStyle(color: Colors.white54),
                    hintText: '09...',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Pay 249 ETB', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 15),
              const Center(child: Text('🔒 Secure payment', style: TextStyle(color: Colors.white54, fontSize: 12))),
            ],
          ),
        ),
      ),
    );
  }
}
