import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_pintar/shared_widgets.dart';

/// Rute disederhanakan: tiap halaman hanya menampilkan path-nya, karena yang
/// diuji di sini adalah navigasinya, bukan isi halaman.
GoRouter buildTestRouter({String initialLocation = '/'}) {
  Widget page(String path) => Scaffold(
        bottomNavigationBar: const AppNavigationBar(),
        body: Center(child: Text(path)),
      );

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (_, __) => page('/')),
      GoRoute(path: '/products', builder: (_, __) => page('/products')),
      GoRoute(path: '/scan', builder: (_, __) => page('/scan')),
      GoRoute(path: '/excel-import', builder: (_, __) => page('/excel-import')),
      GoRoute(path: '/stock-in', builder: (_, __) => page('/stock-in')),
      GoRoute(path: '/history', builder: (_, __) => page('/history')),
      GoRoute(path: '/product-form', builder: (_, __) => page('/product-form')),
      GoRoute(path: '/receipt/1', builder: (_, __) => page('/receipt/1')),
    ],
  );
}

BottomNavigationBar barIn(WidgetTester tester) =>
    tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));

void main() {
  testWidgets('navigasi utama menyediakan kelima fitur', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildTestRouter()));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    for (final label in ['Kasir', 'Produk', 'Scan', 'Stok', 'Riwayat']) {
      expect(find.text(label), findsOneWidget, reason: 'tab $label hilang');
    }
  });

  testWidgets('tab Stok menyalakan untuk tambah stok maupun impor produk', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: buildTestRouter(initialLocation: '/stock-in'),
      ),
    );
    await tester.pumpAndSettle();
    expect(barIn(tester).currentIndex, 3);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: buildTestRouter(initialLocation: '/excel-import'),
      ),
    );
    await tester.pumpAndSettle();
    expect(barIn(tester).currentIndex, 3);
  });

  testWidgets('tab aktif mengikuti rute yang sedang dibuka', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: buildTestRouter(initialLocation: '/history'),
      ),
    );
    await tester.pumpAndSettle();

    expect(barIn(tester).currentIndex, 4);
  });

  testWidgets('halaman anak tetap menyalakan tab induknya', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: buildTestRouter(initialLocation: '/product-form'),
      ),
    );
    await tester.pumpAndSettle();

    expect(barIn(tester).currentIndex, 1);
  });

  testWidgets('menekan tab berpindah ke rute fitur tersebut', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildTestRouter()));
    await tester.pumpAndSettle();

    expect(find.text('/'), findsOneWidget);

    await tester.tap(find.text('Produk'));
    await tester.pumpAndSettle();
    expect(find.text('/products'), findsOneWidget);

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    expect(find.text('/scan'), findsOneWidget);
  });
}
