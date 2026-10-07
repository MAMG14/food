import 'dart:ui';

import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/food_item.dart';
import 'package:food/domain/reminders.dart';
import 'package:food/domain/urgency.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/ui/format/expiry_format.dart';

import 'notification_gateway.dart';

/// Builds the localized notification text for [slot] (spec 003 RF-14/15).
ReminderMessage buildReminderMessage(
  ReminderSlot slot,
  AppLocalizations l10n,
  Locale locale,
  DateTime today,
) {
  final id = reminderNotificationId(slot);
  // Relative words ("today"/"tomorrow") refer to when the user reads it.
  final readOn = slot.immediate ? today : slot.fireAt;

  String expires(FoodItem item) =>
      l10n.reminderItemExpires(item.name, _when(item, l10n, locale, readOn));

  if (slot.items.length == 1) {
    return ReminderMessage(
      id: id,
      title: l10n.appTitle,
      body: expires(slot.items.single),
    );
  }

  final lines = slot.items.map(expires).toList();
  return ReminderMessage(
    id: id,
    title: l10n.reminderGroupTitle(slot.items.length),
    body: slot.items.map((i) => i.name).join(', '),
    lines: lines,
  );
}

String _when(FoodItem item, AppLocalizations l10n, Locale locale, DateTime on) {
  final days = daysUntilExpiry(item, on);
  if (days <= 0) return l10n.reminderWhenToday;
  if (days == 1) return l10n.reminderWhenTomorrow;
  final formatted = formatExpiry(item, locale);
  return item.expiryPrecision == ExpiryPrecision.month
      ? l10n.reminderWhenInMonth(formatted)
      : l10n.reminderWhenOn(formatted);
}
