import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';

class _NavTab {
  final String path;
  final String label;
  final IconData icon;

  const _NavTab({required this.path, required this.label, required this.icon});
}

/// Navigasi utama aplikasi: satu tab untuk setiap fitur tingkat atas.
///
/// Tab aktif dihitung dari rute yang sedang dibuka, bukan dari state halaman,
/// supaya penanda tetap benar setelah pindah lewat rute mana pun.
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({super.key});

  static const List<_NavTab> _tabs = [
    _NavTab(path: '/', label: 'Kasir', icon: Icons.point_of_sale),
    _NavTab(path: '/products', label: 'Produk', icon: Icons.inventory_2_outlined),
    _NavTab(path: '/scan', label: 'Scan', icon: Icons.qr_code_scanner),
    _NavTab(path: '/stock-in', label: 'Stok', icon: Icons.file_upload),
    _NavTab(path: '/history', label: 'Riwayat', icon: Icons.history),
  ];

  @override
  Widget build(BuildContext context) {
    // Garis 1px sebagai pemisah struktural sesuai desainbrief: struktur terlihat
    // lewat border, bukan lewat bayangan.
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _indexFor(GoRouterState.of(context).matchedLocation),
        onTap: (index) => context.go(_tabs[index].path),
        items: [
          for (final tab in _tabs)
            BottomNavigationBarItem(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }

  /// Halaman anak menyalakan tab induknya, mis. /product-form -> Produk dan
  /// /receipt/3 -> Riwayat.
  static int _indexFor(String location) {
    if (location == '/') return 0;
    if (location.startsWith('/product')) return 1;
    if (location.startsWith('/scan')) return 2;
    if (location.startsWith('/stock-in') ||
        location.startsWith('/stock-history') ||
        location.startsWith('/excel-import')) {
      return 3;
    }
    if (location.startsWith('/history') || location.startsWith('/receipt')) return 4;
    return 0;
  }
}
