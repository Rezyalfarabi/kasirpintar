import 'package:flutter/material.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/theme/app_text_styles.dart';
import 'package:kasir_pintar/core/theme/app_spacing.dart';
import 'package:kasir_pintar/core/theme/app_radius.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: AppTextStyles.fontFamily,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accentYellow,
      onPrimary: AppColors.textOnYellow,
      primaryContainer: AppColors.yellowDeep,
      onPrimaryContainer: AppColors.textOnYellow,
      secondary: AppColors.baseBlack,
      onSecondary: AppColors.baseWhite,
      surface: AppColors.baseWhite,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.offWhite,
      error: AppColors.dangerLine,
      onError: AppColors.baseWhite,
      outline: AppColors.borderLight,
      outlineVariant: AppColors.borderDark,
      shadow: AppColors.shadow,
    ),
    scaffoldBackgroundColor: AppColors.baseWhite,
    canvasColor: AppColors.baseWhite,
    cardColor: AppColors.cardBackground,
    dividerColor: AppColors.divider,
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 0,
      indent: 0,
      endIndent: 0,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.baseWhite,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: AppTextStyles.heading,
      toolbarHeight: 56,
    ),
    textTheme: TextTheme(
      displayLarge: AppTextStyles.display,
      displayMedium: AppTextStyles.display.copyWith(fontSize: 24),
      displaySmall: AppTextStyles.display.copyWith(fontSize: 20),
      headlineLarge: AppTextStyles.heading,
      headlineMedium: AppTextStyles.heading.copyWith(fontSize: 18),
      headlineSmall: AppTextStyles.heading.copyWith(fontSize: 16),
      titleLarge: AppTextStyles.subheading,
      titleMedium: AppTextStyles.subheading.copyWith(fontSize: 15),
      titleSmall: AppTextStyles.subheading.copyWith(fontSize: 14),
      bodyLarge: AppTextStyles.body.copyWith(fontSize: 16),
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
      labelLarge: AppTextStyles.buttonPrimary,
      labelMedium: AppTextStyles.buttonSecondary,
      labelSmall: AppTextStyles.badge,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.inputPaddingHorizontal,
        vertical: AppSpacing.inputPaddingVertical,
      ),
      labelStyle: AppTextStyles.inputLabel,
      hintStyle: AppTextStyles.inputHint,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.inputBorder, width: 1),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.inputBorder, width: 1),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.inputBorderFocus, width: 2),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.dangerLine, width: 1),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.dangerLine, width: 2),
      ),
      disabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.disabled, width: 1),
      ),
      errorStyle: AppTextStyles.caption.copyWith(color: AppColors.dangerLine),
      counterStyle: AppTextStyles.caption,
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.buttonPaddingHorizontal,
        vertical: AppSpacing.buttonPaddingVertical,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentYellow,
        foregroundColor: AppColors.textOnYellow,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.buttonPaddingHorizontal,
          vertical: AppSpacing.buttonPaddingVertical,
        ),
        textStyle: AppTextStyles.buttonPrimary,
        minimumSize: const Size(88, 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        side: const BorderSide(color: AppColors.borderDark, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.buttonPaddingHorizontal,
          vertical: AppSpacing.buttonPaddingVertical,
        ),
        textStyle: AppTextStyles.buttonSecondary,
        minimumSize: const Size(88, 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        textStyle: AppTextStyles.buttonSecondary.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: AppColors.textPrimary,
          decorationThickness: 1,
        ),
        minimumSize: const Size(64, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.all(AppSpacing.sm),
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBackground,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.offWhite,
      disabledColor: AppColors.disabled,
      selectedColor: AppColors.baseBlack,
      secondarySelectedColor: AppColors.accentYellow,
      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
      secondaryLabelStyle: AppTextStyles.caption.copyWith(color: AppColors.textOnYellow),
      brightness: Brightness.light,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.badge),
        side: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
      pressElevation: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.modalBackground,
      elevation: 4,
      shadowColor: AppColors.shadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.modal),
        ),
      ),
      modalBackgroundColor: AppColors.modalBackground,
      dragHandleColor: AppColors.borderLight,
      showDragHandle: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.modalBackground,
      elevation: 4,
      shadowColor: AppColors.shadow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.modal),
      ),
      titleTextStyle: AppTextStyles.heading,
      contentTextStyle: AppTextStyles.body,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.baseBlack,
      contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.baseWhite),
      actionTextColor: AppColors.accentYellow,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentYellow,
      foregroundColor: AppColors.textOnYellow,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.baseWhite,
      selectedItemColor: AppColors.baseBlack,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: AppTextStyles.caption,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.textPrimary,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.baseBlack,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: AppTextStyles.subheading,
      unselectedLabelStyle: AppTextStyles.subheading.copyWith(fontWeight: FontWeight.normal),
      dividerColor: AppColors.borderLight,
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (states) => states.contains(WidgetState.pressed)
            ? AppColors.accentYellow.withValues(alpha: 0.1)
            : null,
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.listItemPaddingHorizontal,
        vertical: AppSpacing.xs,
      ),
      titleTextStyle: AppTextStyles.subheading,
      subtitleTextStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      leadingAndTrailingTextStyle: AppTextStyles.caption,
      iconColor: AppColors.textSecondary,
      shape: const Border(
        bottom: BorderSide(color: AppColors.divider, width: 1),
      ),
      horizontalTitleGap: AppSpacing.md,
      minVerticalPadding: AppSpacing.listItemPaddingVertical,
    ),
    // Indikator memuat memakai hitam, bukan kuning: kuning di atas putih hanya
    // sekitar 1.6:1 dan praktis tidak terlihat. Kuning tetap untuk aksi.
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.baseBlack,
      linearTrackColor: AppColors.offWhite,
      circularTrackColor: AppColors.offWhite,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.accentYellow,
      inactiveTrackColor: AppColors.offWhite,
      thumbColor: AppColors.accentYellow,
      overlayColor: AppColors.accentYellow.withValues(alpha: 0.2),
      valueIndicatorColor: AppColors.baseBlack,
      valueIndicatorTextStyle: AppTextStyles.caption.copyWith(color: AppColors.baseWhite),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.accentYellow
            : AppColors.disabled,
      ),
      trackColor: WidgetStateProperty.resolveWith<Color?>(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.accentYellow.withValues(alpha: 0.5)
            : AppColors.borderLight,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.accentYellow
            : AppColors.borderLight,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.accentYellow
            : Colors.transparent,
      ),
      checkColor: WidgetStateProperty.all(AppColors.textOnYellow),
      side: const BorderSide(color: AppColors.borderDark, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xs)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.accentYellow
            : AppColors.borderDark,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.baseBlack,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      textStyle: AppTextStyles.caption.copyWith(color: AppColors.baseWhite),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      verticalOffset: AppSpacing.sm,
      preferBelow: true,
    ),
  );
}