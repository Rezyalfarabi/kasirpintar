import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Membuka database drift di web.
///
/// Membutuhkan `sqlite3.wasm` dan `drift_worker.js` di folder `web/`.
/// Lihat https://drift.simonbinder.eu/platforms/web/ untuk cara mendapatkannya.
Future<QueryExecutor> openDatabaseConnection() async {
  final result = await WasmDatabase.open(
    databaseName: 'kasir_pintar',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
  );
  return result.resolvedExecutor;
}
