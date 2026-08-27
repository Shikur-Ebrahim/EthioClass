import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';
import '../../services/session_service.dart';

class PersonalInfoScreen extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String currentPhone;
  final String accessToken;

  const PersonalInfoScreen({
    super.key,
    required this.currentName,
    required this.currentEmail,
    required this.currentPhone,
    this.accessToken = '',
  });

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    
    // Hide the dummy email we generate during signup so the user can enter a real one
    String initialEmail = widget.currentEmail;
    if (initialEmail.endsWith('@ethioclass.com') && initialEmail.replaceAll('@ethioclass.com', '').length == 10) {
      initialEmail = '';
    }
    
    _emailController = TextEditingController(text: initialEmail);
    _phoneController = TextEditingController(text: widget.currentPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.accessToken.isEmpty) {
      _showSnack('Session expired. Please log in again.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService().updateProfile(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        accessToken: widget.accessToken,
      );

      // Also update session locally so the app remembers the new email
      await SessionService.saveSession(
        token: widget.accessToken,
        userName: _nameController.text.trim(),
        userEmail: _emailController.text.trim(),
        userPhone: _phoneController.text.trim(),
        userRole: 'user', // keep user
      );

      if (!mounted) return;
      _showSnack('Profile updated successfully!');
      Navigator.pop(context, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
      });
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
        title: const Text('Personal Information',
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
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 32),

              const Text('Full Name', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Enter your full name',
                prefixIcon: Icons.person_outline,
                controller: _nameController,
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 20),

              const Text('Email Address', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Your email address',
                prefixIcon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v != null && v.isNotEmpty && !v.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text('Phone Number', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Enter your phone number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                controller: _phoneController,
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter your phone number' : null,
              ),

              const SizedBox(height: 40),
              PrimaryButton(
                text: 'Save Changes',
                onPressed: _saveChanges,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
