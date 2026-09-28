import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_pintar/core/theme/app_theme.dart';
import 'package:kasir_pintar/core/di/providers.dart';
import 'package:kasir_pintar/core/constants/app_constants.dart';
import 'package:kasir_pintar/data/datasources/local/app_database.dart';
import 'package:kasir_pintar/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await AppDatabase.create();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const KasirPintarApp(),
    ),
  );
}

class KasirPintarApp extends ConsumerWidget {
  const KasirPintarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final theme = buildAppTheme();

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1).clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}