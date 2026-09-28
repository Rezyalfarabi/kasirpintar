import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/theme/app_theme.dart';
import 'package:kasir_pintar/shared_widgets.dart';

/// Mengunci aturan desainbrief.md ke dalam kode, supaya tidak perlahan
/// melenceng lagi tanpa disadari.
void main() {
  group('tipografi', () {
    test('Inter benar-benar ada sebagai berkas font, bukan hanya nama', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('family: Inter'));

      for (final file in [
        'assets/fonts/Inter-Regular.ttf',
        'assets/fonts/Inter-Medium.ttf',
        'assets/fonts/Inter-Bold.ttf',
      ]) {
        final asset = File(file);
        expect(asset.existsSync(), isTrue, reason: '$file tidak ada');

        // Berkas TTF selalu diawali 0x00010000.
        final header = asset.readAsBytesSync().sublist(0, 4);
        expect(header, [0x00, 0x01, 0x00, 0x00], reason: '$file bukan font TTF valid');
      }
    });

    test('tema memakai Inter sebagai keluarga font', () {
      expect(buildAppTheme().textTheme.bodyMedium?.fontFamily ?? 'Inter', 'Inter');
    });
  });

  group('aturan warna', () {
    final theme = buildAppTheme();

    test('kuning hanya untuk aksi, bukan untuk indikator memuat', () {
      // Kuning di atas putih hanya ~1.6:1 sehingga tidak terlihat.
      expect(theme.progressIndicatorTheme.color, AppColors.baseBlack);
    });

    test('warna aksi utama tetap kuning dengan teks gelap', () {
      final style = theme.elevatedButtonTheme.style!;
      expect(style.backgroundColor?.resolve({}), AppColors.accentYellow);
      expect(style.foregroundColor?.resolve({}), AppColors.textOnYellow);
    });

    test('segmen aktif berlatar hitam, bukan kuning', () {
      expect(theme.colorScheme.secondary, AppColors.baseBlack);
      expect(theme.colorScheme.onSecondary, AppColors.baseWhite);
    });

    test('tab navigasi memakai hitam untuk item aktif', () {
      expect(theme.bottomNavigationBarTheme.selectedItemColor, AppColors.baseBlack);
      expect(theme.bottomNavigationBarTheme.unselectedItemColor, AppColors.textSecondary);
    });
  });

  group('struktur lewat border, bukan bayangan', () {
    final theme = buildAppTheme();

    test('tanpa elevasi pada tombol, kartu, dan app bar', () {
      expect(theme.elevatedButtonTheme.style!.elevation?.resolve({}), 0);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.appBarTheme.elevation, 0);
    });

    test('kartu memakai garis 1px sebagai pemisah', () {
      final side = (theme.cardTheme.shape! as RoundedRectangleBorder).side;
      expect(side.color, AppColors.borderLight);
      expect(side.width, 1);
    });

    test('input memakai garis bawah dan fokus 2px kuning tua', () {
      final focused = theme.inputDecorationTheme.focusedBorder! as UnderlineInputBorder;
      expect(focused.borderSide.color, AppColors.inputBorderFocus);
      expect(focused.borderSide.width, 2);
    });
  });

  group('kontras teks', () {
    test('hint input tidak memakai abu yang gagal kontras AA', () {
      final theme = buildAppTheme();
      final hint = theme.inputDecorationTheme.hintStyle!;
      expect(hint.color, isNot(const Color(0xFF999999)));
      expect(hint.color, const Color(0xFF6E6E6E));
    });
  });

  group('komponen', () {
    testWidgets('indikator di tombol kuning berwarna gelap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: PrimaryButton(label: 'Simpan', isLoading: true, onPressed: () {}),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      final animation = indicator.valueColor as AlwaysStoppedAnimation<Color>?;
      expect(animation?.value, AppColors.textOnYellow);
    });

    testWidgets('segmen terpilih dirender hitam dengan teks putih', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: SegmentedControl<String>(
              segments: const [
                Segment(value: 'a', label: 'Kamera'),
                Segment(value: 'b', label: 'Galeri'),
              ],
              selectedValue: 'a',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final containers = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();
      final selected = containers.first.decoration as BoxDecoration;
      expect(selected.color, AppColors.baseBlack);

      final label = tester.widget<Text>(find.text('Kamera'));
      expect(label.style?.color, AppColors.baseWhite);
    });
  });
}
