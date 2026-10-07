import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/reminder_settings.dart';
import 'package:sqflite/sqflite.dart';

import 'food_database.dart';

/// Persists [ReminderSettings] in SQLite (single row + per-category rules).
class ReminderSettingsRepository {
  ReminderSettingsRepository(this._foodDatabase);

  final FoodDatabase _foodDatabase;

  Future<Database> get _db => _foodDatabase.database;

  Future<ReminderSettings> load() async {
    final db = await _db;
    final rows = await db.query('reminder_settings', where: 'id = 1', limit: 1);
    final ruleRows = await db.query('category_reminder_rules');

    final rules = <Category, CategoryReminderRule>{};
    for (final row in ruleRows) {
      final category = Category.values.asNameMap()[row['category']];
      final mode = ReminderRuleMode.values.asNameMap()[row['mode']];
      if (category == null || mode == null) continue;
      final rule = switch (mode) {
        ReminderRuleMode.general => null,
        ReminderRuleMode.custom => CategoryReminderRule.custom(row['lead_days'] as int),
        ReminderRuleMode.off => const CategoryReminderRule.off(),
      };
      if (rule != null) rules[category] = rule;
    }

    if (rows.isEmpty) {
      return ReminderSettings.defaults.copyWith(categoryRules: rules);
    }
    final row = rows.first;
    return ReminderSettings(
      enabled: row['enabled'] == 1,
      generalLeadDays: row['general_lead_days'] as int,
      notifyHour: row['notify_hour'] as int,
      notifyMinute: row['notify_minute'] as int,
      permissionAsked: row['permission_asked'] == 1,
      categoryRules: rules,
    );
  }

  Future<void> save(ReminderSettings settings) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert(
        'reminder_settings',
        {
          'id': 1,
          'enabled': settings.enabled ? 1 : 0,
          'general_lead_days': settings.generalLeadDays,
          'notify_hour': settings.notifyHour,
          'notify_minute': settings.notifyMinute,
          'permission_asked': settings.permissionAsked ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete('category_reminder_rules');
      for (final entry in settings.categoryRules.entries) {
        await txn.insert('category_reminder_rules', {
          'category': entry.key.name,
          'mode': entry.value.mode.name,
          'lead_days': entry.value.leadDays,
        });
      }
    });
  }
}
