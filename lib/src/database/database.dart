import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart'; // Still needed for NativeDatabase
part 'database.g.dart';

// These annotations tell drift to prepare a table for us.
@DataClassName('UserEntry')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get email => text().unique()();
}

@DriftDatabase(tables: [Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  // Singleton instance for the database
  static AppDatabase? _instance;
  static AppDatabase get instance {
    _instance ??= AppDatabase(_openConnection());
    return _instance!;
  }

  @override
  int get schemaVersion => 1; // Used for migrations

  // Example queries
  Future<List<UserEntry>> getAllUsers() => select(users).get();
  Future<UserEntry?> getUserById(int id) =>
      (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();
  Future<int> createUser(UsersCompanion entry) => into(users).insert(entry);
  Future<int> deleteUser(int id) =>
      (delete(users)..where((u) => u.id.equals(id))).go();

  // You can also write raw SQL queries if needed:
  // Future<List<User>> rawUsers() => customSelect('SELECT * FROM users').map((row) => User.fromData(row.data, this)).get();
}

// Function to open the database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final appEnv = Platform.environment['APP_ENV'];
    final dbPath = appEnv == 'production'
        ? p.join('/app', 'data', 'app.db') // Docker path
        : p.join(Directory.current.path, 'data', 'app.db'); // Local path

    final file = File(dbPath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }

    // Initialize SQLite if it hasn't been done (important for some platforms)
    sqlite3.open(dbPath); // This line just ensures sqlite3 is loaded

    return NativeDatabase(file);
  });
}
