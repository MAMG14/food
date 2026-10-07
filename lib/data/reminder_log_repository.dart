import 'package:food/domain/reminders.dart';
import 'package:sqflite/sqflite.dart';

import 'food_database.dart';

/// Remembers, per item, which reminder was scheduled at the last resync.
class ReminderLogRepository {
  ReminderLogRepository(this._foodDatabase);

  final FoodDatabase _foodDatabase;

  Future<Database> get _db => _foodDatabase.database;

  Future<Map<int, ReminderLogEntry>> load() async {
    final rows = await (await _db).query('reminder_log');
    return {
      for (final row in rows)
        row['item_id'] as int: ReminderLogEntry(
          fireAt: DateTime.parse(row['fire_at'] as String),
          expiryKey: row['expiry_key'] as String,
        ),
    };
  }

  /// Replaces the whole log (items no longer listed are forgotten).
  Future<void> replaceAll(Map<int, ReminderLogEntry> log) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('reminder_log');
      for (final entry in log.entries) {
        await txn.insert('reminder_log', {
          'item_id': entry.key,
          'fire_at': entry.value.fireAt.toIso8601String(),
          'expiry_key': entry.value.expiryKey,
        });
      }
    });
  }
}
