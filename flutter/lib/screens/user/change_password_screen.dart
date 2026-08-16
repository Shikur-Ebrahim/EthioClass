import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String accessToken;

  const ChangePasswordScreen({super.key, this.accessToken = ''});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
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
      appBar: AppBar(
        title: const Text('Change Password',
            style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold)),
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
              const Text(
                'Create a strong password that you don\'t use for other websites.',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 32),

              const Text('New Password', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Enter new password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                controller: _newPasswordController,
                validator: (v) => (v == null || v.length < 6)
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 20),

              const Text('Confirm New Password', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Confirm your new password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                controller: _confirmPasswordController,
                validator: (v) {
                  if (v != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
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
