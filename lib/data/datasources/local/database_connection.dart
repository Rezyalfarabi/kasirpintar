import 'package:drift/drift.dart';

import 'package:kasir_pintar/data/datasources/local/database_connection_native.dart'
    if (dart.library.js_interop)
        'package:kasir_pintar/data/datasources/local/database_connection_web.dart';

Future<QueryExecutor> createDatabaseConnection() => openDatabaseConnection();
