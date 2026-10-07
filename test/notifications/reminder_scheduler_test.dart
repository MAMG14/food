import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:food/data/food_database.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/data/reminder_log_repository.dart';
import 'package:food/data/reminder_settings_repository.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/food_item.dart';
import 'package:food/domain/models/reminder_settings.dart';
import 'package:food/notifications/reminder_scheduler.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_notification_gateway.dart';

FoodItem food(
  String name,
  String value, {
  ExpiryPrecision precision = ExpiryPrecision.day,
  Category category = Category.other,
}) {
  return FoodItem(
    name: name,
    expiryPrecision: precision,
    expiryValue: value,
    quantity: 1,
    unit: Unit.pz,
    category: category,
    location: StorageLocation.other,
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;
  late FoodDatabase db;
  late FoodItemRepository items;
  late ReminderSettingsRepository settings;
  late FakeNotificationGateway gateway;
  late DateTime now;

  ReminderScheduler scheduler({Locale locale = const Locale('es')}) {
    return ReminderScheduler(
      items: items,
      settings: settings,
      log: ReminderLogRepository(db),
      gateway: gateway,
      locale: locale,
      clock: () => now,
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('food_scheduler_test_');
    db = FoodDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: p.join(tempDir.path, 'test.db'),
    );
    items = FoodItemRepository(db);
    settings = ReminderSettingsRepository(db);
    gateway = FakeNotificationGateway();
    now = DateTime(2026, 10, 6, 8); // before default 09:00
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test('schedules one reminder per day with singular text', () async {
    await items.insert(food('Leche', '2026-10-08'));
    await scheduler().resync();

    expect(gateway.cancelAllCalls, 1);
    final (message, fireAt) = gateway.scheduled.values.single;
    expect(fireAt, DateTime(2026, 10, 6, 9));
    expect(message.title, 'Food');
    expect(message.body, 'Leche caduca el 8 de octubre de 2026');
    expect(message.lines, isEmpty);
  });

  test('"tomorrow" is relative to the reminder day, not to now', () async {
    await settings.save(ReminderSettings.defaults.copyWith(generalLeadDays: 1));
    await items.insert(food('Yogur', '2026-10-20'));
    await scheduler().resync();

    final (message, fireAt) = gateway.scheduled.values.single;
    expect(fireAt, DateTime(2026, 10, 19, 9));
    expect(message.body, 'Yogur caduca mañana');
  });

  test('groups items of the same day with plural title and lines', () async {
    await items.insert(food('Queso', '2026-10-10'));
    await items.insert(food('Jamón', '2026-10-10'));
    await scheduler().resync();

    final (message, _) = gateway.scheduled.values.single;
    expect(message.title, '2 artículos por caducar');
    expect(message.body, 'Jamón, Queso');
    expect(message.lines, hasLength(2));
  });

  test('month precision says "en <mes>"', () async {
    await settings.save(ReminderSettings.defaults.copyWith(generalLeadDays: 7));
    await items.insert(food('Arroz', '2026-11', precision: ExpiryPrecision.month));
    await scheduler().resync();

    final (message, _) = gateway.scheduled.values.single;
    expect(message.body, 'Arroz caduca en noviembre de 2026');
  });

  test('texts follow the given locale (no hardcoded language)', () async {
    await items.insert(food('Milk', '2026-10-07'));
    await items.insert(food('Bread', '2026-10-07'));
    await items.insert(food('Ham', '2026-10-12'));
    await scheduler(locale: const Locale('en')).resync();

    final messages = gateway.scheduled.values.map((e) => e.$1).toList();
    expect(messages.first.title, '2 items expiring soon');
    expect(messages.first.lines, ['Bread expires tomorrow', 'Milk expires tomorrow']);
    expect(messages.last.body, 'Ham expires on October 12, 2026');
  });

  test('deleting an item removes its reminder on next resync', () async {
    final leche = await items.insert(food('Leche', '2026-10-10'));
    await scheduler().resync();
    expect(gateway.scheduled, hasLength(1));

    await items.delete(leche.id!);
    await scheduler().resync();
    expect(gateway.scheduled, isEmpty);
  });

  test('disabled reminders schedule nothing', () async {
    await items.insert(food('Leche', '2026-10-10'));
    await settings.save(ReminderSettings.defaults.copyWith(enabled: false));
    await scheduler().resync();
    expect(gateway.scheduled, isEmpty);
    expect(gateway.shownNow, isEmpty);
  });

  test('a delivered reminder is not repeated on later days', () async {
    await items.insert(food('Leche', '2026-10-08'));
    await scheduler().resync(); // scheduled today 09:00

    now = DateTime(2026, 10, 6, 18); // it fired at 09:00
    await scheduler().resync();
    expect(gateway.scheduled, isEmpty);
    expect(gateway.shownNow, isEmpty);
  });

  test('immediate reminder is shown once, not on every resync', () async {
    now = DateTime(2026, 10, 6, 18);
    await items.insert(food('Pan', '2026-10-06'));

    await scheduler().resync();
    await scheduler().resync();
    expect(gateway.shownNow.single.body, 'Pan caduca hoy');
  });

  test('editing the expiry reminds again for the new date', () async {
    final leche = await items.insert(food('Leche', '2026-10-08'));
    await scheduler().resync();
    now = DateTime(2026, 10, 6, 18);
    await scheduler().resync();
    expect(gateway.scheduled, isEmpty);

    await items.update(leche.copyWith(expiryValue: '2026-10-15'));
    await scheduler().resync();
    expect(gateway.scheduled.values.single.$2, DateTime(2026, 10, 13, 9));
  });

  test('concurrent resync calls do not interleave', () async {
    await items.insert(food('Leche', '2026-10-10'));
    final s = scheduler();
    await Future.wait([s.resync(), s.resync(), s.resync()]);
    expect(gateway.scheduled, hasLength(1));
    expect(gateway.cancelAllCalls, lessThanOrEqualTo(2));
  });
}
