import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:food/ui/theme/food_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Prefer the classic (non edge-to-edge) layout so the status bar and DEBUG
  // banner stay fully visible, as before the splash work.
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
  SystemChrome.setSystemUIOverlayStyle(appSystemOverlayStyle);
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
