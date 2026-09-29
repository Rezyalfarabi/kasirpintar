import 'package:flutter/material.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/theme/app_radius.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String? title;

  /// Judul kaya (mis. nama aplikasi + keterangan halaman). Dipakai kalau satu
  /// baris teks saja tidak cukup menjelaskan halaman.
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBottomBorder;
  final Color? backgroundColor;
  final double elevation;

  const AppBarWidget({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBottomBorder = true,
    this.backgroundColor,
    this.elevation = 0,
  }) : assert(
          title != null || titleWidget != null,
          'AppBarWidget butuh title atau titleWidget',
        );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: titleWidget ?? Text(title!, style: theme.appBarTheme.titleTextStyle),
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      elevation: elevation,
      surfaceTintColor: Colors.transparent,
      bottom: showBottomBorder
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: theme.dividerColor,
              ),
            )
          : null,
    );
  }

  // Tinggi harus menyertakan garis bawah 1px, kalau tidak isi halaman
  // tertimpa garisnya saat showBottomBorder aktif.
  @override
  Size get preferredSize => Size.fromHeight(56 + (showBottomBorder ? 1 : 0));
}

/// Penanda aplikasi untuk bar atas: kotak hitam dengan ikon aplikasi.
class AppBrandMark extends StatelessWidget {
  final double size;

  const AppBrandMark({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        color: AppColors.baseBlack,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Image.asset(
        'img/iconaplikasikasir.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
