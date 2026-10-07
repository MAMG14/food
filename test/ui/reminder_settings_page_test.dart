import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food/data/food_database.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/data/reminder_log_repository.dart';
import 'package:food/data/reminder_settings_repository.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/reminder_settings.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/notifications/reminder_scheduler.dart';
import 'package:food/ui/settings/reminder_settings_page.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../notifications/fake_notification_gateway.dart';

/// Real DB IO completes outside the fake clock, but its continuations run in
/// the test zone: alternate real waits with pumps.
Future<void> settle(WidgetTester tester, {int rounds = 10}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;
  late FoodDatabase db;
  late ReminderSettingsRepository settings;
  late FakeNotificationGateway gateway;
  late ReminderScheduler reminders;
  final l10n = lookupAppLocalizations(const Locale('es'));

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('food_settings_page_test_');
    db = FoodDatabase(
      databaseFactory: databaseFactoryFfi,
      databasePath: p.join(tempDir.path, 'test.db'),
    );
    settings = ReminderSettingsRepository(db);
    gateway = FakeNotificationGateway();
    reminders = ReminderScheduler(
      items: FoodItemRepository(db),
      settings: settings,
      log: ReminderLogRepository(db),
      gateway: gateway,
      locale: const Locale('es'),
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<void> pumpPage(WidgetTester tester) async {
    // Narrow (360 dp) but tall so every category row is built (ListView is lazy).
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ReminderSettingsPage(reminders: reminders),
      ),
    );
    for (var i = 0; i < 100; i++) {
      await settle(tester, rounds: 1);
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    await settle(tester);
  }

  testWidgets('shows defaults: enabled, 2 days, 09:00, categories general', (tester) async {
    await pumpPage(tester);

    expect(find.text(l10n.reminderEnabled), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);
    expect(find.text(l10n.reminderLeadDays(2)), findsOneWidget);
    final context = tester.element(find.byType(ReminderSettingsPage));
    expect(find.text(const TimeOfDay(hour: 9, minute: 0).format(context)), findsOneWidget);
    expect(
      find.text(l10n.reminderRuleGeneral(l10n.reminderLeadDays(2))),
      findsNWidgets(Category.values.length),
    );
    expect(find.text(l10n.reminderPermissionDenied), findsNothing);
  });

  testWidgets('turning reminders off is saved', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byType(SwitchListTile));
    // Let the save and the resync it triggers finish before the DB is deleted.
    await settle(tester);

    final saved = await tester.runAsync(settings.load);
    expect(saved!.enabled, isFalse);
  });

  testWidgets('shows banner when permission is denied', (tester) async {
    gateway.enabled = false;
    await pumpPage(tester);

    expect(find.text(l10n.reminderPermissionDenied), findsOneWidget);
    await tester.tap(find.text(l10n.reminderOpenSettings));
    expect(gateway.settingsOpened, 1);
  });

  testWidgets('loads a saved category rule', (tester) async {
    await tester.runAsync(
      () => settings.save(
        ReminderSettings.defaults.withRule(
          Category.pantry,
          const CategoryReminderRule.off(),
        ),
      ),
    );
    await pumpPage(tester);
    expect(find.text(l10n.reminderRuleOff), findsOneWidget);
  });
}
