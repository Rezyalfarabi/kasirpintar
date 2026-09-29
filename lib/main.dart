import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasir_pintar/core/theme/app_colors.dart';
import 'package:kasir_pintar/core/theme/app_theme.dart';
import 'package:kasir_pintar/core/di/providers.dart';
import 'package:kasir_pintar/core/constants/app_constants.dart';
import 'package:kasir_pintar/data/datasources/local/app_database.dart';
import 'package:kasir_pintar/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Basis data dibuka PARALEL dengan gambar pertama, tidak ditunggu sebelum
  // runApp. Di web, AppDatabase menunggu download sqlite3.wasm dan
  // drift_worker.js; kalau di-await di sini, browser cuma menampilkan layar
  // kosong selama itu dan terasa "lama buka". BootApp memunculkan splash dulu.
  final database = AppDatabase.create();

  runApp(BootApp(database: database));
}

/// Layar boot dipakai dua kasus: basis data masih dibuka, atau basis data gagal
/// dibuka. Keduanya dihias supaya pengguna tidak melihat jendela kosong.
class BootScreen extends StatelessWidget {
  const BootScreen({super.key, this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final theme = buildAppTheme();
    return MaterialApp(
      title: AppConstants.appName,
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.accentYellow,
        body: Center(
          child: error == null
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Kasir Pintar gagal dibuka',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Menampilkan splash seketika, lalu mengganti ke aplikasi begitu basis data
/// siap. ProviderScope dibuat di sini supaya `databaseProvider` hanya
/// tersedia setelah basis data benar-benar terisi.
class BootApp extends StatefulWidget {
  const BootApp({super.key, required this.database});

  final Future<AppDatabase> database;

  @override
  State<BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<BootApp> {
  AppDatabase? _database;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final database = await widget.database;
      if (!mounted) return;
      setState(() => _database = database);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_database != null) {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(_database!),
        ],
        child: const KasirPintarApp(),
      );
    }
    return BootScreen(error: _error);
  }
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