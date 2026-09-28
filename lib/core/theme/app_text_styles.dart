import 'package:flutter/material.dart';

class AppTextStyles {
  static const String fontFamily = 'Inter';

  // Dipakai untuk total harga, jadi angkanya memakai tabular figures agar
  // digit tidak bergeser saat nilai berubah.
  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: Color(0xFF111111),
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle heading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: Color(0xFF111111),
    letterSpacing: -0.3,
  );

  static const TextStyle subheading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Color(0xFF111111),
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: Color(0xFF111111),
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Color(0xFF666666),
  );

  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    height: 1.4,
    color: Color(0xFF111111),
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Color(0xFF111111),
  );

  static const TextStyle inputLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Color(0xFF111111),
  );

  // #6E6E6E, bukan #999999: abu terang gagal kontras AA (2.9:1) untuk teks 14px.
  static const TextStyle inputHint = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: Color(0xFF6E6E6E),
  );

  static const TextStyle price = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Color(0xFF111111),
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle priceDisplay = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: Color(0xFF111111),
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle barcode = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Color(0xFF666666),
    letterSpacing: 0.5,
  );

  static const TextStyle badge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: Color(0xFF111111),
  );

  static const TextStyle receiptMonospace = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: Color(0xFF111111),
  );
}