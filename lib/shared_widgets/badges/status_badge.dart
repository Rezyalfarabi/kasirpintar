import 'package:flutter/material.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/theme/app_radius.dart';

enum BadgeType {
  attention,
  danger,
  success,
  neutral,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    switch (type) {
      case BadgeType.attention:
        backgroundColor = AppColors.accentYellow;
        borderColor = AppColors.accentYellow;
        textColor = AppColors.textOnYellow;
      case BadgeType.danger:
        backgroundColor = Colors.transparent;
        borderColor = AppColors.dangerLine;
        textColor = AppColors.dangerLine;
      case BadgeType.success:
        backgroundColor = Colors.transparent;
        borderColor = AppColors.successLine;
        textColor = AppColors.successLine;
      case BadgeType.neutral:
        backgroundColor = AppColors.offWhite;
        borderColor = AppColors.borderLight;
        textColor = AppColors.textPrimary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.2,
        ),
      ),
    );
  }
}