import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:food/data/food_database.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/data/reminder_log_repository.dart';
import 'package:food/data/reminder_settings_repository.dart';
import 'package:food/domain/reminders.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/reminder_settings.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;
  late String dbPath;
  late FoodDatabase foodDb;
  late ReminderSettingsRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('food_settings_test_');
    dbPath = p.join(tempDir.path, 'test.db');
    foodDb = FoodDatabase(databaseFactory: databaseFactoryFfi, databasePath: dbPath);
    repo = ReminderSettingsRepository(foodDb);
  });

  tearDown(() async {
    await foodDb.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('returns spec defaults when nothing was saved', () async {
    final s = await repo.load();
    expect(s.enabled, isTrue);
    expect(s.generalLeadDays, 2);
    expect(s.notifyHour, 9);
    expect(s.notifyMinute, 0);
    expect(s.permissionAsked, isFalse);
    expect(s.categoryRules, isEmpty);
  });

  test('saves and loads every field', () async {
    final saved = ReminderSettings.defaults
        .copyWith(
          enabled: false,
          generalLeadDays: 14,
          notifyHour: 20,
          notifyMinute: 45,
          permissionAsked: true,
        )
        .withRule(Category.meat, const CategoryReminderRule.custom(1))
        .withRule(Category.pantry, const CategoryReminderRule.off());
    await repo.save(saved);

    final loaded = await repo.load();
    expect(loaded.enabled, isFalse);
    expect(loaded.generalLeadDays, 14);
    expect(loaded.notifyHour, 20);
    expect(loaded.notifyMinute, 45);
    expect(loaded.permissionAsked, isTrue);
    expect(loaded.ruleFor(Category.meat), const CategoryReminderRule.custom(1));
    expect(loaded.ruleFor(Category.pantry), const CategoryReminderRule.off());
    expect(loaded.ruleFor(Category.dairy), const CategoryReminderRule.useGeneral());
  });

  test('saving again replaces rules (removed rule goes back to general)', () async {
    await repo.save(
      ReminderSettings.defaults.withRule(Category.meat, const CategoryReminderRule.off()),
    );
    await repo.save(ReminderSettings.defaults);
    final loaded = await repo.load();
    expect(loaded.categoryRules, isEmpty);
  });

  test('settings survive reopening the database', () async {
    await repo.save(ReminderSettings.defaults.copyWith(generalLeadDays: 5));
    await foodDb.close();

    final reopened = FoodDatabase(databaseFactory: databaseFactoryFfi, databasePath: dbPath);
    final loaded = await ReminderSettingsRepository(reopened).load();
    await reopened.close();
    expect(loaded.generalLeadDays, 5);
  });

  test('reminder log replaces and reloads entries', () async {
    final logRepo = ReminderLogRepository(foodDb);
    expect(await logRepo.load(), isEmpty);

    final entry = ReminderLogEntry(
      fireAt: DateTime(2026, 10, 8, 9),
      expiryKey: 'day:2026-10-10',
    );
    await logRepo.replaceAll({1: entry, 2: entry});
    await logRepo.replaceAll({2: entry});
    expect(await logRepo.load(), {2: entry});
  });

  test('migrates a v1 database without losing items', () async {
    await foodDb.close();

    final v1 = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute(FoodDatabase.createFoodItemsSql);
          await db.insert('food_items', {
            'name': 'Leche',
            'expiry_precision': 'day',
            'expiry_value': '2026-12-01',
            'quantity': 1.0,
            'unit': 'pz',
            'category': 'dairy',
            'notes': null,
            'location': 'fridge',
            'created_at': '2026-10-01T00:00:00',
            'updated_at': '2026-10-01T00:00:00',
          });
        },
      ),
    );
    await v1.close();

    foodDb = FoodDatabase(databaseFactory: databaseFactoryFfi, databasePath: dbPath);
    final items = await FoodItemRepository(foodDb).getAll();
    expect(items.map((i) => i.name), ['Leche']);

    final settings = await ReminderSettingsRepository(foodDb).load();
    expect(settings.generalLeadDays, 2);
    expect(await ReminderLogRepository(foodDb).load(), isEmpty);
    expect(await (await foodDb.database).getVersion(), FoodDatabase.schemaVersion);
  });
}
