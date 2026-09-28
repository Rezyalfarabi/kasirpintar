import 'package:flutter/material.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/shared_widgets/badges/status_badge.dart';

class ListRow extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final Color? dividerColor;
  final EdgeInsetsGeometry? padding;

  const ListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.dividerColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.zero,
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppSpacing.listItemPaddingHorizontal,
                  vertical: AppSpacing.listItemPaddingVertical,
                ),
            child: Row(
              children: [
                leading,
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      title,
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        subtitle!,
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: dividerColor ?? AppColors.divider,
            indent: 0,
            endIndent: 0,
          ),
      ],
    );
  }
}

class ListRowWithBadge extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final String? badgeText;
  final BadgeType? badgeType;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const ListRowWithBadge({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.badgeType,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListRow(
      leading: leading,
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: subtitle != null
          ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeText != null && badgeType != null)
            StatusBadge(label: badgeText!, type: badgeType!),
          if (trailing != null) trailing!,
        ],
      ),
      onTap: onTap,
      showDivider: showDivider,
    );
  }
}