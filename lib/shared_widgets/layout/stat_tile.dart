import 'package:flutter/material.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/theme/app_radius.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/theme/app_text_styles.dart';

/// Angka ringkas dengan label kecil di bawahnya.
///
/// Dipakai untuk baris ringkasan di atas daftar, jadi angkanya sengaja besar
/// dan labelnya huruf kapital kecil supaya tidak bersaing dengan isi daftar.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? tone;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isSelected;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.tone,
    this.icon,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = tone ?? AppColors.textPrimary;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: valueColor),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  value,
                  style: AppTextStyles.display.copyWith(fontSize: 22, color: valueColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.badge.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return Material(
      color: isSelected ? AppColors.accentYellow : AppColors.baseWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.structural),
        side: BorderSide(
          color: isSelected ? AppColors.accentYellow : AppColors.borderLight,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.structural),
        child: content,
      ),
    );
  }
}
