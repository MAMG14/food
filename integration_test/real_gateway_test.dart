import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food/data/food_database.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/data/reminder_log_repository.dart';
import 'package:food/data/reminder_settings_repository.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/food_item.dart';
import 'package:food/domain/models/reminder_settings.dart';
import 'package:food/notifications/local_notification_gateway.dart';
import 'package:food/notifications/reminder_scheduler.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

String _day(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

FoodItem _food(String name, DateTime expiry) => FoodItem(
  name: name,
  expiryPrecision: ExpiryPrecision.day,
  expiryValue: _day(expiry),
  quantity: 1,
  unit: Unit.pz,
  category: Category.other,
  location: StorageLocation.other,
);

/// Spec 003 T5/T7 on a real device: the OS holds the expected pending reminders.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FoodDatabase db;
  late FoodItemRepository items;
  late ReminderSettingsRepository settings;
  late ReminderScheduler scheduler;
  final plugin = FlutterLocalNotificationsPlugin();

  setUp(() async {
    FoodDatabase.ensureInitialized();
    final path = p.join(await getDatabasesPath(), 'integration_real_gateway.db');
    await deleteDatabase(path);
    db = FoodDatabase(databasePath: path);
    items = FoodItemRepository(db);
    settings = ReminderSettingsRepository(db);

    final gateway = LocalNotificationGateway(
      channelName: 'Recordatorios',
      channelDescription: 'Avisos de caducidad',
    );
    await gateway.init();
    // iOS refuses to schedule without authorization and simctl cannot grant
    // it: allow the system dialog once and run with --no-uninstall so the
    // grant survives the next run.
    if (!await gateway.areEnabled()) {
      final granted = await gateway.requestPermission().timeout(
        const Duration(minutes: 2),
        onTimeout: () => false,
      );
      if (!granted) {
        fail(
          'Food no tiene permiso de notificaciones: pulsa «Permitir» en el '
          'diálogo (o actívalo en Ajustes) y repite con --no-uninstall.',
        );
      }
    }
    await gateway.cancelAll();
    scheduler = ReminderScheduler(
      items: items,
      settings: settings,
      log: ReminderLogRepository(db),
      gateway: gateway,
      locale: const Locale('es'),
    );
  });

  tearDown(() async {
    await plugin.cancelAll();
    await db.close();
  });

  testWidgets('resync programa, agrupa y cancela avisos en el sistema', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    // Default lead is 2 days at 09:00, so these fire in 3 and 8 days.
    final milk = await items.insert(_food('Leche', today.add(const Duration(days: 5))));
    await items.insert(_food('Yogur', today.add(const Duration(days: 5))));
    await items.insert(_food('Queso', today.add(const Duration(days: 10))));

    await scheduler.resync();
    var pending = await plugin.pendingNotificationRequests();
    expect(pending, hasLength(2));
    final group = pending.singleWhere((r) => r.title == '2 artículos por caducar');
    expect(group.body, 'Leche, Yogur');
    expect(pending.map((r) => r.body), contains(startsWith('Queso caduca')));

    await items.delete(milk.id!);
    await scheduler.resync();
    pending = await plugin.pendingNotificationRequests();
    expect(pending, hasLength(2));
    expect(pending.map((r) => r.title).toSet(), {'Food'});
    expect(
      pending.map((r) => r.body),
      containsAll([startsWith('Yogur caduca'), startsWith('Queso caduca')]),
    );

    await settings.save(ReminderSettings.defaults.copyWith(enabled: false));
    await scheduler.resync();
    expect(await plugin.pendingNotificationRequests(), isEmpty);
  });
}
