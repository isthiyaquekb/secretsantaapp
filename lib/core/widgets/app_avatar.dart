import 'package:flutter/material.dart';
import 'package:secretsantaapp/core/theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool isTwoLetter;
  final bool isCompleted;

  const AppAvatar({
    super.key,
    required this.name,
    this.size = 36.0,
    this.isTwoLetter = false,
    this.isCompleted = false,
  });

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';

    if (isTwoLetter) {
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
      }
      return trimmed.length >= 2
          ? trimmed.substring(0, 2).toUpperCase()
          : trimmed[0].toUpperCase();
    }

    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isCompleted
        ? (isDark ? const Color(0xFF2E2224) : AppColors.lightSurfaceContainerLow)
        : (isDark ? AppColors.darkAvatarBg : AppColors.lightAvatarBg);

    final textColor = isCompleted
        ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
        : (isDark ? AppColors.darkAvatarText : AppColors.lightAvatarText);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Text(
        _initials,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

