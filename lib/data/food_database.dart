import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens and migrates the local Food SQLite database.
///
/// - v1: `food_items` (spec 001).
/// - v2: reminder settings + reminder log tables (spec 003).
class FoodDatabase {
  FoodDatabase({
    DatabaseFactory? databaseFactory,
    this.databasePath,
  }) : _databaseFactory = databaseFactory;

  final DatabaseFactory? _databaseFactory;

  /// Optional absolute path; defaults to app databases dir + [dbName].
  final String? databasePath;

  Database? _db;

  static const dbName = 'food.db';
  static const schemaVersion = 2;

  static const createFoodItemsSql = '''
CREATE TABLE food_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  expiry_precision TEXT NOT NULL,
  expiry_value TEXT NOT NULL,
  quantity REAL NOT NULL,
  unit TEXT NOT NULL,
  category TEXT NOT NULL,
  notes TEXT,
  location TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''';

  static const _createReminderSettingsSql = '''
CREATE TABLE reminder_settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  enabled INTEGER NOT NULL,
  general_lead_days INTEGER NOT NULL,
  notify_hour INTEGER NOT NULL,
  notify_minute INTEGER NOT NULL,
  permission_asked INTEGER NOT NULL
)
''';

  static const _createCategoryRulesSql = '''
CREATE TABLE category_reminder_rules (
  category TEXT PRIMARY KEY,
  mode TEXT NOT NULL,
  lead_days INTEGER
)
''';

  static const _createReminderLogSql = '''
CREATE TABLE reminder_log (
  item_id INTEGER PRIMARY KEY,
  fire_at TEXT NOT NULL,
  expiry_key TEXT NOT NULL
)
''';

  /// Ensures a global [databaseFactory] exists (Android/iOS plugin).
  ///
  /// Call once at app startup. Tests should set [databaseFactory] to FFI first.
  static void ensureInitialized() {
    databaseFactoryOrNull ??= databaseFactorySqflitePlugin;
  }

  /// Default on-disk path (`…/food.db`) used when [databasePath] is null.
  static Future<String> defaultDatabaseFilePath() async {
    return p.join(await getDatabasesPath(), dbName);
  }

  /// Whether the default DB file already exists (upgrade vs clean install).
  ///
  /// Call **before** the first [openDatabase] in a session (spec 004).
  static Future<bool> defaultDatabaseFileExists() async {
    return File(await defaultDatabaseFilePath()).exists();
  }

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbFactory =
        _databaseFactory ??
        databaseFactoryOrNull ??
        databaseFactorySqflitePlugin;
    final path = databasePath ?? p.join(await getDatabasesPath(), dbName);
    return dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: (db, version) async {
          await db.execute(createFoodItemsSql);
          await _createV2(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Only additive changes: never drop or rewrite food_items.
          if (oldVersion < 2) await _createV2(db);
        },
      ),
    );
  }

  static Future<void> _createV2(Database db) async {
    await db.execute(_createReminderSettingsSql);
    await db.execute(_createCategoryRulesSql);
    await db.execute(_createReminderLogSql);
  }

  Future<void> close() async {
    final existing = _db;
    if (existing != null) {
      await existing.close();
      _db = null;
    }
  }
}
