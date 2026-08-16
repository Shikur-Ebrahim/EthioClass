import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class PersonalInfoScreen extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String currentPhone;

  const PersonalInfoScreen({
    super.key,
    required this.currentName,
    required this.currentEmail,
    required this.currentPhone,
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
    _emailController = TextEditingController(text: widget.currentEmail);
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
    
    setState(() => _isLoading = true);
    try {
      // In a real app, you'd get the access token from secure storage.
      // Here we assume it's available or we pass it, but for now we simulate success
      // since we don't have a global state manager setup yet.
      
      // await AuthService().updateProfile(
      //   fullName: _nameController.text.trim(),
      //   phoneNumber: _phoneController.text.trim(),
      //   accessToken: '...', 
      // );
      
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Personal Information', style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold)),
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
                validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 20),
              
              const Text('Email Address', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Your email address',
                prefixIcon: Icons.email_outlined,
                controller: _emailController,
                enabled: false, // Email usually cannot be changed easily
              ),
              const SizedBox(height: 20),
              
              const Text('Phone Number', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AppTextField(
                hint: 'Enter your phone number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                controller: _phoneController,
                validator: (v) => v!.isEmpty ? 'Please enter your phone number' : null,
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
