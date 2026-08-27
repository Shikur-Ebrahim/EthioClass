import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../widgets/auth_widgets.dart';
import '../user/main_layout.dart';
import '../admin/admin_home_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final result = await AuthService().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      // Safely extract user name and email — always navigate even if parsing fails
      String userName = '';
      String userEmail = _emailController.text.trim();
      String userPhone = '';
      String accessToken = '';
      String userRole = 'user';
      try {
        accessToken = (result['token'] as String?) ?? '';
        userPhone = (result['phone_number'] as String?) ?? '';
        userRole = (result['role'] as String?) ?? 'user';
        final user = result['user'];
        if (user is Map) {
          userEmail = (user['email'] as String?) ?? userEmail;
          final meta = user['user_metadata'];
          if (meta is Map) {
            userName = (meta['full_name'] as String?) ?? '';
            // fallback: phone from metadata if not in profile yet
            if (userPhone.isEmpty) {
              userPhone = (meta['phone_number'] as String?) ?? '';
            }
          }
        }
      } catch (_) {}

      // Save session for persistent login
      await SessionService.saveSession(
        token: accessToken,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        userRole: userRole,
      );

      if (!mounted) return;
      
      if (userRole == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => AdminHomeScreen(
              userName: userName,
              userEmail: userEmail,
            ),
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MainLayout(
              userName: userName,
              userEmail: userEmail,
              userPhone: userPhone,
              accessToken: accessToken,
            ),
          ),
          (route) => false,
        );
      }
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
                              color: Colors.black.withOpacity(0.06), blurRadius: 8),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: AppColors.navy),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // Logo icon
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.greyLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school_rounded,
                              size: 36, color: AppColors.primary),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Center(
                        child: Text('Welcome Back!', style: AppTextStyles.headline2),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Login to continue your learning',
                          style: AppTextStyles.subtitle,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Email label + field
                      const Text('Email or Phone Number', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      AppTextField(
                        hint: 'Enter your phone number or email',
                        prefixIcon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter your phone number or email' : null,
                      ),

                      const SizedBox(height: 18),

                      // Password label + field
                      const Text('Password', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      AppTextField(
                        hint: 'Enter your password',
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        controller: _passwordController,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Enter your password' : null,
                      ),

                      const SizedBox(height: 10),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                            );
                          },
                          child: const Text('Forgot Password?', style: AppTextStyles.link),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Login button
                      PrimaryButton(
                        text: 'Login',
                        onPressed: _login,
                        isLoading: _isLoading,
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.greyLight)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or login with',
                                style: AppTextStyles.body.copyWith(color: AppColors.grey)),
                          ),
                          const Expanded(child: Divider(color: AppColors.greyLight)),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Google
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

                      // Facebook
                      SocialButton(
                        label: 'Facebook',
                        icon: const Icon(Icons.facebook_rounded,
                            color: Color(0xFF1877F2), size: 24),
                        onPressed: () {},
                      ),

                      const SizedBox(height: 28),

                      // Sign up link
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? ",
                                style: AppTextStyles.body),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const SignupScreen()),
                              ),
                              child: const Text('Sign Up', style: AppTextStyles.link),
                            ),
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
