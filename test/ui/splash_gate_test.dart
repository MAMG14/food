import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food/app.dart';
import 'package:food/data/food_database.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/data/reminder_log_repository.dart';
import 'package:food/data/reminder_settings_repository.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/notifications/reminder_scheduler.dart';
import 'package:food/ui/home/inventory_page.dart';
import 'package:food/ui/splash/food_mark.dart';
import 'package:food/ui/splash/splash_gate.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../notifications/fake_notification_gateway.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;
  late FoodDatabase foodDb;
  late FoodItemRepository repo;
  late ReminderScheduler reminders;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('food_splash_test_');
    foodDb = FoodDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: p.join(tempDir.path, 'test.db'),
    );
    repo = FoodItemRepository(foodDb);
    reminders = ReminderScheduler(
      items: repo,
      settings: ReminderSettingsRepository(foodDb),
      log: ReminderLogRepository(foodDb),
      gateway: FakeNotificationGateway(),
      locale: const Locale('es'),
    );
  });

  tearDown(() async {
    await foodDb.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('splash shows brand then fades to inventory', (tester) async {
    const splashDuration = Duration(milliseconds: 400);

    await tester.pumpWidget(
      FoodApp(repository: repo, reminders: reminders, splashDuration: splashDuration),
    );
    await tester.pump();

    expect(find.byType(SplashView), findsOneWidget);
    expect(find.byType(FoodMark), findsOneWidget);
    expect(find.byType(InventoryPage), findsNothing);

    final l10n = lookupAppLocalizations(const Locale('es'));
    expect(find.text(l10n.appTitle), findsWidgets);
    expect(find.text(l10n.splashTagline), findsOneWidget);

    await tester.pump(splashDuration);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SplashView), findsNothing);
    expect(find.byType(InventoryPage), findsOneWidget);
    expect(find.text(l10n.tabActive), findsOneWidget);
  });

  testWidgets('zero duration skips branded splash', (tester) async {
    await tester.pumpWidget(
      FoodApp(repository: repo, reminders: reminders, splashDuration: Duration.zero),
    );
    await tester.pump();

    expect(find.byType(SplashView), findsNothing);
    expect(find.byType(InventoryPage), findsOneWidget);
  });
}
