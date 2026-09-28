import 'package:flutter/material.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/theme/app_radius.dart';

class SegmentedControl<T> extends StatelessWidget {
  final List<Segment<T>> segments;
  final T? selectedValue;
  final ValueChanged<T>? onChanged;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;

  const SegmentedControl({
    super.key,
    required this.segments,
    this.selectedValue,
    this.onChanged,
    this.selectedColor,
    this.unselectedColor,
    this.selectedTextColor,
    this.unselectedTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Sesuai desainbrief: segmen aktif berlatar hitam dengan teks putih. Kalau
    // memakai kuning, satu layar jadi punya dua kuning dan maknanya kabur.
    final effectiveSelectedColor = selectedColor ?? theme.colorScheme.secondary;
    final effectiveUnselectedColor = unselectedColor ?? Colors.transparent;
    final effectiveSelectedTextColor = selectedTextColor ?? theme.colorScheme.onSecondary;
    final effectiveUnselectedTextColor = unselectedTextColor ?? theme.colorScheme.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline, width: 1),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: segments.asMap().entries.map((entry) {
          final index = entry.key;
          final segment = entry.value;
          final isSelected = selectedValue == segment.value;
          final isFirst = index == 0;
          final isLast = index == segments.length - 1;

          return Expanded(
            child: GestureDetector(
              onTap: onChanged != null ? () => onChanged!(segment.value) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? effectiveSelectedColor : effectiveUnselectedColor,
                  borderRadius: BorderRadius.horizontal(
                    left: isFirst ? const Radius.circular(AppRadius.button) : Radius.zero,
                    right: isLast ? const Radius.circular(AppRadius.button) : Radius.zero,
                  ),
                  border: Border(
                    right: isLast
                        ? BorderSide.none
                        : BorderSide(
                            color: theme.colorScheme.outline,
                            width: 1,
                          ),
                  ),
                ),
                child: Center(
                  child: Text(
                    segment.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected ? effectiveSelectedTextColor : effectiveUnselectedTextColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class Segment<T> {
  final T value;
  final String label;
  final IconData? icon;

  const Segment({
    required this.value,
    required this.label,
    this.icon,
  });
}