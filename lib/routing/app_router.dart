import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_pintar/features/product/presentation/pages/product_list_page.dart';
import 'package:kasir_pintar/features/product/presentation/pages/product_form_page.dart';
import 'package:kasir_pintar/features/transaction/presentation/pages/transaction_page.dart';
import 'package:kasir_pintar/features/transaction/presentation/pages/history_page.dart';
import 'package:kasir_pintar/features/excel_import/presentation/pages/excel_import_page.dart';
import 'package:kasir_pintar/features/receipt/presentation/pages/receipt_page.dart';
import 'package:kasir_pintar/features/barcode/presentation/pages/barcode_scan_page.dart';
import 'package:kasir_pintar/features/stock_in/presentation/pages/stock_in_page.dart';
import 'package:kasir_pintar/features/stock_history/presentation/pages/stock_history_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'transaction',
        builder: (context, state) => const TransactionPage(),
      ),
      GoRoute(
        path: '/products',
        name: 'products',
        builder: (context, state) => const ProductListPage(),
      ),
      GoRoute(
        path: '/product-form',
        name: 'productForm',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          final productId = params['id'];
          return ProductFormPage(
            productId: productId != null ? int.tryParse(productId) : null,
            initialBarcode: params['barcode'],
          );
        },
      ),
      GoRoute(
        path: '/excel-import',
        name: 'excelImport',
        builder: (context, state) => const ExcelImportPage(),
      ),
      GoRoute(
        path: '/stock-in',
        name: 'stockIn',
        builder: (context, state) => const StockInPage(),
      ),
      GoRoute(
        path: '/stock-history',
        name: 'stockHistory',
        builder: (context, state) {
          final productId = state.uri.queryParameters['productId'];
          return StockHistoryPage(
            productId: productId != null ? int.tryParse(productId) : null,
          );
        },
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: '/receipt/:id',
        name: 'receipt',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return ReceiptPage(transactionId: id ?? 0);
        },
      ),
      GoRoute(
        path: '/scan',
        name: 'scan',
        builder: (context, state) => const BarcodeScanPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Halaman tidak ditemukan: ${state.error}'),
      ),
    ),
  );
});