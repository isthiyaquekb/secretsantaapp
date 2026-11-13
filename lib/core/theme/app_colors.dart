import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Light Theme Colors ---
  static const Color lightBackground = Color(0xFFF9F7F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerHigh = Color(0xFFF7E3E6);
  static const Color lightSurfaceContainerLow = Color(0xFFFFF0F1);
  static const Color lightTextPrimary = Color(0xFF1E1416);
  static const Color lightTextMuted = Color(0xFF756C6C);
  static const Color lightDivider = Color(0xFFE7E1E1);
  static const Color lightPrimary = Color(0xFF9E1B26); // Deep Christmas red
  static const Color lightPrimaryVibrant = Color(0xFFFF3F33); // Stitch accent
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightAvatarBg = Color(0xFFF7E3E6);
  static const Color lightAvatarText = Color(0xFFA7373F);

  // --- Dark Theme Colors ---
  static const Color darkBackground = Color(0xFF171112);
  static const Color darkSurface = Color(0xFF221819);
  static const Color darkSurfaceContainerHigh = Color(0xFF2E2224);
  static const Color darkSurfaceContainerLow = Color(0xFF1C1516);
  static const Color darkTextPrimary = Color(0xFFF5ECEC);
  static const Color darkTextMuted = Color(0xFFA59B9B);
  static const Color darkDivider = Color(0xFF2D2426);
  static const Color darkPrimary = Color(0xFFE5656B); // Softened luminescent rose-red
  static const Color darkOnPrimary = Color(0xFF171112);
  static const Color darkAvatarBg = Color(0xFF332325);
  static const Color darkAvatarText = Color(0xFFFFB3B3);

  // --- Common Status / Confetti Colors ---
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color confettiRed = Color(0xFF9E1B26);
  static const Color confettiGold = Color(0xFFFFD700);
  static const Color confettiGreen = Color(0xFF2E7D32);

  // Legacy compatibility references
  static const Color appPrimaryColor = lightPrimary;
  static const Color appScaffoldColor = lightBackground;
  static const Color appTextColor = lightTextPrimary;
}

