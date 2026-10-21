import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food/app.dart';
import 'package:food/data/app_preferences.dart';
import 'package:food/data/food_database.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/data/reminder_log_repository.dart';
import 'package:food/data/reminder_settings_repository.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/notifications/reminder_scheduler.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../test/notifications/fake_notification_gateway.dart';

/// Pumps real frames until [done] holds or [timeout] passes.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() done,
  String what, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (done()) return;
  }
  throw TestFailure('Timed out after $timeout waiting for $what');
}

Future<void> pumpUntilFound(WidgetTester tester, Finder finder) =>
    pumpUntil(tester, () => finder.evaluate().isNotEmpty, '$finder');

/// Spec 003 T7/T9 end to end (updated for 004 Home shell).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final l10n = lookupAppLocalizations(const Locale('es'));
  late FoodDatabase db;
  late FakeNotificationGateway gateway;
  late AppPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.onboardingCompletedKey: true,
    });
    preferences = AppPreferences(prefs: await SharedPreferences.getInstance());
    FoodDatabase.ensureInitialized();
    final path = p.join(await getDatabasesPath(), 'integration_app_flow.db');
    await deleteDatabase(path);
    db = FoodDatabase(databasePath: path);
    gateway = FakeNotificationGateway();
  });

  tearDown(() => db.close());

  testWidgets('crear artículo programa aviso y tocar aviso abre Por caducar', (
    tester,
  ) async {
    final repository = FoodItemRepository(db);
    final settings = ReminderSettingsRepository(db);
    await tester.pumpWidget(
      FoodApp(
        repository: repository,
        reminders: ReminderScheduler(
          items: repository,
          settings: settings,
          log: ReminderLogRepository(db),
          gateway: gateway,
          locale: const Locale('es'),
        ),
        preferences: preferences,
        splashDuration: const Duration(milliseconds: 300),
      ),
    );

    final nameField = find.widgetWithText(TextField, l10n.fieldName);
    List<String> reminderBodies() => [
      ...gateway.scheduled.values.map((s) => s.$1.body),
      ...gateway.shownNow.map((m) => m.body),
    ];

    await pumpUntilFound(tester, find.text(l10n.emptyActive));
    await pumpUntil(tester, () => gateway.permissionRequests > 0, 'permission');
    expect(gateway.permissionRequests, 1);
    expect((await settings.load()).permissionAsked, isTrue);

    await tester.tap(find.text(l10n.navAdd));
    await pumpUntilFound(tester, nameField);
    await tester.enterText(nameField, 'Leche');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 500));
    final save = find.widgetWithText(FilledButton, l10n.save);
    await tester.scrollUntilVisible(
      save,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(save);
    await pumpUntil(tester, () => nameField.evaluate().isEmpty, 'form closed');
    await pumpUntilFound(tester, find.text('Leche'));
    await pumpUntil(tester, () => reminderBodies().isNotEmpty, 'reminder');
    expect(reminderBodies(), contains(startsWith('Leche caduca')));

    await tester.tap(find.text(l10n.filterExpired));
    await pumpUntilFound(tester, find.text(l10n.emptyExpired));
    await tester.tap(find.text(l10n.navAdd));
    await pumpUntilFound(tester, nameField);

    gateway.tapController.add(null);
    await pumpUntil(
      tester,
      () => nameField.evaluate().isEmpty,
      'form closed by tap',
    );
    await pumpUntilFound(tester, find.text('Leche'));
  });
}
