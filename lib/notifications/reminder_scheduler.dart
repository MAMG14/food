import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/data/reminder_log_repository.dart';
import 'package:food/data/reminder_settings_repository.dart';
import 'package:food/domain/expiry.dart';
import 'package:food/domain/reminders.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'notification_gateway.dart';
import 'reminder_messages.dart';

/// Rebuilds every pending reminder from current items and settings.
class ReminderScheduler {
  ReminderScheduler({
    required this.items,
    required this.settings,
    required this.log,
    required this.gateway,
    required this.locale,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final FoodItemRepository items;
  final ReminderSettingsRepository settings;
  final ReminderLogRepository log;
  final NotificationGateway gateway;
  final Locale locale;
  final DateTime Function() _clock;

  Future<void>? _running;
  bool _again = false;

  /// Safe to call often; overlapping calls collapse into one extra run.
  Future<void> resync() {
    if (_running != null) {
      _again = true;
      return _running!;
    }
    return _running = _loop().whenComplete(() => _running = null);
  }

  Future<void> _loop() async {
    do {
      _again = false;
      try {
        await _resyncOnce();
      } catch (e, st) {
        debugPrint('Reminder resync failed: $e\n$st');
      }
    } while (_again);
  }

  Future<void> _resyncOnce() async {
    final now = _clock();
    final all = await items.getAll();
    final config = await settings.load();
    final previous = await log.load();
    final l10n = lookupAppLocalizations(locale);
    // May run before MaterialApp loads date symbols (e.g. at startup).
    await initializeDateFormatting(locale.toLanguageTag());

    final notified = notifiedItemIds(all, previous, now);
    final slots = planReminders(all, config, now, alreadyNotified: notified);

    await gateway.cancelAll();
    for (final slot in slots) {
      final message = buildReminderMessage(slot, l10n, locale, dateOnly(now));
      if (slot.immediate) {
        await gateway.showNow(message);
      } else {
        await gateway.schedule(message, slot.fireAt);
      }
    }

    await log.replaceAll({
      for (final id in notified) id: previous[id]!,
      for (final slot in slots)
        for (final item in slot.items)
          item.id!: ReminderLogEntry(
            fireAt: slot.fireAt,
            expiryKey: reminderExpiryKey(item),
          ),
    });
  }
}
