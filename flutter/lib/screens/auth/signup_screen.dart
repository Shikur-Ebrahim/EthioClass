import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreedToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showSnack('Please agree to the Terms of Service', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService().signup(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: '+251${_phoneController.text.trim()}',
        password: _passwordController.text,
      );
      if (!mounted) return;
      _showSnack('Account created successfully! Please log in.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: AppColors.navy),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text('Create Account', style: AppTextStyles.headline2),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      const Text(
                        'Join EthioClass and start your learning journey',
                        style: AppTextStyles.subtitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Avatar icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.greyLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add_outlined,
                            size: 32, color: AppColors.primary),
                      ),

                      const SizedBox(height: 28),

                      // Full Name
                      AppTextField(
                        hint: 'Full Name',
                        prefixIcon: Icons.person_outline_rounded,
                        controller: _nameController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
                      ),
                      const SizedBox(height: 14),

                      // Email
                      AppTextField(
                        hint: 'Email Address',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter your email';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Phone Number with Ethiopian flag prefix
                      AppTextField(
                        hint: 'Phone Number',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        controller: _phoneController,
                        prefixWidget: Container(
                          padding: const EdgeInsets.only(left: 14, right: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🇪🇹', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 4),
                              const Text('+251',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w600,
                                  )),
                              const SizedBox(width: 6),
                              Container(
                                  width: 1, height: 22, color: AppColors.greyLight),
                              const SizedBox(width: 4),
                            ],
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter your phone number' : null,
                      ),
                      const SizedBox(height: 14),

                      // Password
                      AppTextField(
                        hint: 'Password',
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        controller: _passwordController,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter a password';
                          if (v.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Confirm Password
                      AppTextField(
                        hint: 'Confirm Password',
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        controller: _confirmPasswordController,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Confirm your password';
                          if (v != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Terms checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _agreedToTerms,
                            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            side: const BorderSide(color: AppColors.grey),
                          ),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.textMedium),
                                children: [
                                  TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Sign Up Button
                      PrimaryButton(
                        text: 'Sign Up',
                        onPressed: _signup,
                        isLoading: _isLoading,
                      ),

                      const SizedBox(height: 20),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.greyLight)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or sign up with',
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.grey)),
                          ),
                          const Expanded(child: Divider(color: AppColors.greyLight)),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Google Button
                      SocialButton(
                        label: 'Google',
                        icon: Image.network(
                          'https://www.google.com/favicon.ico',
                          width: 22,
                          height: 22,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.g_mobiledata, size: 24),
                        ),
                        onPressed: () {},
                      ),

                      const SizedBox(height: 12),

                      // Facebook Button
                      SocialButton(
                        label: 'Facebook',
                        icon: const Icon(Icons.facebook_rounded,
                            color: Color(0xFF1877F2), size: 24),
                        onPressed: () {},
                      ),

                      const SizedBox(height: 24),

                      // Already have account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? ",
                              style: AppTextStyles.body),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            ),
                            child: const Text('Login', style: AppTextStyles.link),
                          ),
                        ],
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
