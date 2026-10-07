import 'expiry.dart';
import 'models/enums.dart';
import 'models/food_item.dart';
import 'models/reminder_settings.dart';

/// Max pending reminder days; keeps well under iOS's 64 pending notifications.
const maxReminderSlots = 30;

/// Notification id used for the "right now" slot (day ids start at 1).
const immediateReminderNotificationId = 0;

/// Days before effective expiry to remind for [category], or null for none.
int? effectiveLeadDays(Category category, ReminderSettings settings) {
  if (!settings.enabled) return null;
  final rule = settings.ruleFor(category);
  return switch (rule.mode) {
    ReminderRuleMode.general => settings.generalLeadDays,
    ReminderRuleMode.custom => rule.leadDays,
    ReminderRuleMode.off => null,
  };
}

/// One notification: every item whose reminder falls on the same day.
class ReminderSlot {
  const ReminderSlot({
    required this.fireAt,
    required this.immediate,
    required this.items,
  });

  /// Local date-time to fire; equals "now" when [immediate].
  final DateTime fireAt;

  /// The reminder time already passed and the item expires today.
  final bool immediate;

  /// Sorted by effective expiry, then name.
  final List<FoodItem> items;
}

/// Computes the reminders to schedule at [now] (local), grouped by day.
///
/// Late reminders (time already passed, item not expired) move to the next
/// notify time not after expiry, or fire immediately if none is left.
/// Items in [alreadyNotified] (ids) got their reminder and are skipped, so
/// a delivered reminder is not treated as late and repeated.
List<ReminderSlot> planReminders(
  List<FoodItem> items,
  ReminderSettings settings,
  DateTime now, {
  Set<int> alreadyNotified = const {},
  int maxSlots = maxReminderSlots,
}) {
  final today = dateOnly(now);
  final byDay = <DateTime, List<FoodItem>>{};
  final immediate = <FoodItem>[];

  for (final item in items) {
    if (alreadyNotified.contains(item.id)) continue;
    final expiry = effectiveExpiryDate(item.expiryPrecision, item.expiryValue);
    if (expiry.isBefore(today)) continue;
    final lead = effectiveLeadDays(item.category, settings);
    if (lead == null) continue;

    var fireAt = _atNotifyTime(expiry.year, expiry.month, expiry.day - lead, settings);
    if (!fireAt.isAfter(now)) {
      final todayAt = _atNotifyTime(today.year, today.month, today.day, settings);
      final next = todayAt.isAfter(now)
          ? todayAt
          : _atNotifyTime(today.year, today.month, today.day + 1, settings);
      if (dateOnly(next).isAfter(expiry)) {
        immediate.add(item);
        continue;
      }
      fireAt = next;
    }
    byDay.putIfAbsent(fireAt, () => []).add(item);
  }

  final slots = <ReminderSlot>[
    if (immediate.isNotEmpty)
      ReminderSlot(fireAt: now, immediate: true, items: _sorted(immediate)),
    for (final entry in byDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)))
      ReminderSlot(fireAt: entry.key, immediate: false, items: _sorted(entry.value)),
  ];
  return slots.take(maxSlots).toList();
}

/// Identifies the expiry a reminder was given for; editing the expiry
/// changes it, so the item is reminded again for the new date.
String reminderExpiryKey(FoodItem item) =>
    '${item.expiryPrecision.name}:${item.expiryValue}';

/// Item ids whose reminder already fired at or before [now] for their
/// current expiry. [log] maps item id → (fireAt, expiryKey) as scheduled.
Set<int> notifiedItemIds(
  List<FoodItem> items,
  Map<int, ReminderLogEntry> log,
  DateTime now,
) {
  return {
    for (final item in items)
      if (item.id != null &&
          log[item.id] != null &&
          !log[item.id]!.fireAt.isAfter(now) &&
          log[item.id]!.expiryKey == reminderExpiryKey(item))
        item.id!,
  };
}

/// What was scheduled for an item at the last resync.
class ReminderLogEntry {
  const ReminderLogEntry({required this.fireAt, required this.expiryKey});

  final DateTime fireAt;
  final String expiryKey;

  @override
  bool operator ==(Object other) =>
      other is ReminderLogEntry &&
      other.fireAt == fireAt &&
      other.expiryKey == expiryKey;

  @override
  int get hashCode => Object.hash(fireAt, expiryKey);
}

/// Stable id per reminder day, so re-scheduling replaces instead of duplicating.
int reminderNotificationId(ReminderSlot slot) {
  if (slot.immediate) return immediateReminderNotificationId;
  final day = DateTime.utc(slot.fireAt.year, slot.fireAt.month, slot.fireAt.day);
  return day.difference(DateTime.utc(2000)).inDays + 1;
}

DateTime _atNotifyTime(int year, int month, int day, ReminderSettings s) =>
    DateTime(year, month, day, s.notifyHour, s.notifyMinute);

List<FoodItem> _sorted(List<FoodItem> items) {
  return List<FoodItem>.of(items)..sort((a, b) {
    final byExpiry = effectiveExpiryDate(a.expiryPrecision, a.expiryValue)
        .compareTo(effectiveExpiryDate(b.expiryPrecision, b.expiryValue));
    if (byExpiry != 0) return byExpiry;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
}
