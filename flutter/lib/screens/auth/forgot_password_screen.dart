import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService().resetPassword(email: _emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Password reset link sent! Check your email.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.06), blurRadius: 8),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: AppColors.navy),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_rounded, color: AppColors.primary, size: 24),
                          SizedBox(width: 8),
                          Text('Ethio',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy)),
                          Text('Class',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            
            const SizedBox(height: 4),
            const Text(
              'Learn Today, Lead Tomorrow',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // Illustration (Envelope + Lock)
                      SizedBox(
                        width: 140,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(Icons.mark_email_unread_outlined,
                                size: 100, color: AppColors.greyLight.withOpacity(0.8)),
                            Positioned(
                              bottom: 10,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.lock_outline_rounded,
                                    color: AppColors.navy, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      const Text('Forgot Password?', style: AppTextStyles.headline2),
                      const SizedBox(height: 12),
                      const Text(
                        "No worries! Enter your email and\nwe'll send you a reset link.",
                        style: AppTextStyles.subtitle,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 36),

                      // Email label + field
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Email Address', style: AppTextStyles.label),
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        hint: 'Enter your email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter your email';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Reset button
                      PrimaryButton(
                        text: 'Send Reset Link',
                        onPressed: _resetPassword,
                        isLoading: _isLoading,
                      ),

                      const SizedBox(height: 24),

                      // Back to Sign in
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.textMedium),
                            SizedBox(width: 6),
                            Text('Back to Sign In',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMedium,
                                )),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
