import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food/app.dart';
import 'package:food/data/app_preferences.dart';
import 'package:food/data/food_database.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/data/reminder_log_repository.dart';
import 'package:food/data/reminder_settings_repository.dart';
import 'package:food/notifications/reminder_scheduler.dart';
import 'package:food/ui/home/inventory_page.dart';
import 'package:food/ui/splash/splash_gate.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
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
  late AppPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.onboardingCompletedKey: true,
    });
    preferences = AppPreferences(prefs: await SharedPreferences.getInstance());
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

  testWidgets('splash shows then fades to inventory', (tester) async {
    await tester.pumpWidget(
      FoodApp(
        repository: repo,
        reminders: reminders,
        preferences: preferences,
      ),
    );
    await tester.pump();

    expect(find.byType(SplashView), findsOneWidget);
    expect(find.byType(InventoryPage), findsNothing);

    // Lottie (~1.5s) or hard fallback (2s); avoid pumpAndSettle (ticker).
    await tester.pump(kSplashFallbackMax);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SplashView), findsNothing);
    expect(find.byType(InventoryPage), findsOneWidget);
  });

  testWidgets('zero duration skips branded splash', (tester) async {
    await tester.pumpWidget(
      FoodApp(
        repository: repo,
        reminders: reminders,
        preferences: preferences,
        splashDuration: Duration.zero,
      ),
    );
    await tester.pump();

    expect(find.byType(SplashView), findsNothing);
    expect(find.byType(InventoryPage), findsOneWidget);
  });
}
