import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:kasir_pintar/core/constants/app_constants.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<QueryExecutor> openDatabaseConnection() async {
  final appDir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(appDir.path, AppConstants.databaseName);
  return NativeDatabase(File(dbPath));
}
