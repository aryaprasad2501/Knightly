import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// App-lifetime database. Override in tests with an in-memory [AppDatabase].
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
