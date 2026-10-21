import 'package:flutter/material.dart';
import 'package:food/app.dart';
import 'package:food/data/app_preferences.dart';
import 'package:food/data/food_database.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/data/reminder_log_repository.dart';
import 'package:food/data/reminder_settings_repository.dart';
import 'package:food/l10n/app_locale.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/notifications/local_notification_gateway.dart';
import 'package:food/notifications/reminder_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FoodDatabase.ensureInitialized();

  final databaseFileExisted = await FoodDatabase.defaultDatabaseFileExists();
  final database = FoodDatabase();
  final repository = FoodItemRepository(database);
  final items = await repository.getAll();

  final preferences = AppPreferences();
  final showOnboarding = await preferences.shouldShowOnboarding(
    databaseFileExisted: databaseFileExisted,
    itemCount: items.length,
  );

  final l10n = lookupAppLocalizations(appLocale);
  final gateway = LocalNotificationGateway(
    channelName: l10n.reminderChannelName,
    channelDescription: l10n.reminderChannelDescription,
  );
  try {
    await gateway.init();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }

  final reminders = ReminderScheduler(
    items: repository,
    settings: ReminderSettingsRepository(database),
    log: ReminderLogRepository(database),
    gateway: gateway,
    locale: appLocale,
  );

  runApp(
    FoodApp(
      repository: repository,
      reminders: reminders,
      preferences: preferences,
      showOnboarding: showOnboarding,
    ),
  );
}
