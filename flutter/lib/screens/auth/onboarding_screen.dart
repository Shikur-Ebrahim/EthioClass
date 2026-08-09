import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/auth_widgets.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Logo + Brand
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/app_icon.png',
                    width: 44,
                    height: 44,
                  ),
                  const SizedBox(width: 10),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Ethio',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        TextSpan(
                          text: 'Class',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Learn Today, Lead Tomorrow',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.grey,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 36),

              // Headline
              const Text(
                'Learn Smarter,',
                textAlign: TextAlign.center,
                style: AppTextStyles.headline1,
              ),
              RichText(
                text: const TextSpan(
                  text: 'Achieve More',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Access high-quality video lessons, notes\nand practice tests from the best\ninstructors anytime, anywhere.',
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle,
              ),

              const SizedBox(height: 32),

              // Illustration Card
              Container(
                width: double.infinity,
                height: 230,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        Icons.school_rounded,
                        size: 100,
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Dot(active: true),
                  const SizedBox(width: 6),
                  _Dot(active: false),
                  const SizedBox(width: 6),
                  _Dot(active: false),
                ],
              ),

              const Spacer(),

              // CTA Buttons
              PrimaryButton(
                text: 'Get Started',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                ),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                text: 'I Already Have an Account',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
              ),

              const SizedBox(height: 20),

              // Trust badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.shield_outlined, size: 14, color: AppColors.grey),
                  SizedBox(width: 5),
                  Text(
                    'Trusted by 15,000+ students across Ethiopia',
                    style: TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.greyLight,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
