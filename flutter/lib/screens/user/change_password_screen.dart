import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../widgets/auth_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String accessToken;

  const ChangePasswordScreen({super.key, this.accessToken = ''});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.accessToken.isEmpty) {
      _showSnack('Session expired. Please log in again.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Step 1: Verify current password by attempting login with stored email
      final session = await SessionService.loadSession();
      final email = session?['email'] ?? '';

      if (email.isEmpty) {
        _showSnack(
          'Could not verify identity. Please log in again.',
          isError: true,
        );
        setState(() => _isLoading = false);
        return;
      }

      // Verify current password using login
      try {
        await AuthService().login(
          email: email,
          password: _currentPasswordController.text,
        );
      } catch (_) {
        _showSnack('Current password is incorrect.', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // Step 2: Update to new password
      await AuthService().updatePassword(
        newPassword: _newPasswordController.text,
        accessToken: widget.accessToken,
      );

      if (!mounted) return;
      _showSnack('Password updated successfully!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + header
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Update Your Password',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Enter your current password, then create a new one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textMedium),
                ),
              ),
              const SizedBox(height: 36),

              // Current Password
              const Text('Current Password', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Enter your current password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                controller: _currentPasswordController,
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Please enter your current password'
                    : null,
              ),
              const SizedBox(height: 20),

              // New Password
              const Text('New Password', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Create a new password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                controller: _newPasswordController,
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'Please enter a new password';
                  if (v.length < 6)
                    return 'Password must be at least 6 characters';
                  if (v == _currentPasswordController.text)
                    return 'New password must be different';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Confirm New Password
              const Text('Confirm New Password', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Confirm your new password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                controller: _confirmPasswordController,
                validator: (v) {
                  if (v != _newPasswordController.text)
                    return 'Passwords do not match';
                  return null;
                },
              ),

              const SizedBox(height: 40),
              PrimaryButton(
                text: 'Update Password',
                onPressed: _updatePassword,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
