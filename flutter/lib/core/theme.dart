import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFBB024);       // Yellow/Gold
  static const Color primaryDark = Color(0xFFE09A15);   // Darker Gold
  static const Color navy = Color(0xFF1A2340);           // Dark Navy text
  static const Color navyLight = Color(0xFF2D3A5C);     // Lighter Navy
  static const Color background = Color(0xFFF0F4F8);    // Light grey background
  static const Color surface = Color(0xFFFFFFFF);        // White
  static const Color grey = Color(0xFF8E9BB5);           // Placeholder text
  static const Color greyLight = Color(0xFFE8EDF5);      // Border/input bg
  static const Color textDark = Color(0xFF1A2340);       // Primary text
  static const Color textMedium = Color(0xFF4A5568);     // Secondary text
  static const Color error = Color(0xFFE53E3E);           // Error red
  static const Color success = Color(0xFF38A169);         // Success green
}

class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    height: 1.2,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    height: 1.2,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textMedium,
    height: 1.5,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textMedium,
  );

  static const TextStyle link = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
}
