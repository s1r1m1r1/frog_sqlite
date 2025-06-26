import 'package:dart_frog/dart_frog.dart';

// lib/src/routes/_middleware.dart
import 'package:frog_sqlite/src/database/database.dart';

Handler middleware(Handler handler) {
  return handler.use(
    provider<AppDatabase>((context) {
      // Get the singleton instance of your Drift database
      final db = AppDatabase.instance;
      return db;
    }),
  );
}
