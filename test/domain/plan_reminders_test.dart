import 'package:flutter_test/flutter_test.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/food_item.dart';
import 'package:food/domain/models/reminder_settings.dart';
import 'package:food/domain/reminders.dart';

FoodItem item(
  String name,
  String value, {
  ExpiryPrecision precision = ExpiryPrecision.day,
  Category category = Category.other,
}) {
  return FoodItem(
    id: name.hashCode,
    name: name,
    expiryPrecision: precision,
    expiryValue: value,
    quantity: 1,
    unit: Unit.pz,
    category: category,
    location: StorageLocation.other,
  );
}

void main() {
  // Tuesday 2026-10-06, 08:00 local — before the default 09:00 notify time.
  final morning = DateTime(2026, 10, 6, 8);
  // Same day, 18:00 — after the notify time.
  final evening = DateTime(2026, 10, 6, 18);
  const settings = ReminderSettings.defaults; // 2 days ahead at 09:00

  group('planReminders — single item', () {
    test('normal: fires lead days before expiry at notify time', () {
      final slots = planReminders([item('Leche', '2026-10-10')], settings, morning);
      expect(slots, hasLength(1));
      expect(slots.single.fireAt, DateTime(2026, 10, 8, 9));
      expect(slots.single.immediate, isFalse);
    });

    test('target later today still fires today', () {
      final slots = planReminders([item('Leche', '2026-10-08')], settings, morning);
      expect(slots.single.fireAt, DateTime(2026, 10, 6, 9));
    });

    test('late: target passed, moves to next notify time before expiry', () {
      // Expires 10-07, target 10-05 09:00 already passed; today's 09:00 passed too.
      final slots = planReminders([item('Leche', '2026-10-07')], settings, evening);
      expect(slots.single.fireAt, DateTime(2026, 10, 7, 9));
      expect(slots.single.immediate, isFalse);
    });

    test('late: uses today if notify time has not passed yet', () {
      final slots = planReminders([item('Leche', '2026-10-07')], settings, morning);
      expect(slots.single.fireAt, DateTime(2026, 10, 6, 9));
    });

    test('late: expires today and notify time passed → immediate', () {
      final slots = planReminders([item('Leche', '2026-10-06')], settings, evening);
      expect(slots.single.immediate, isTrue);
      expect(slots.single.fireAt, evening);
    });

    test('expires today before notify time → today at notify time', () {
      final slots = planReminders([item('Leche', '2026-10-06')], settings, morning);
      expect(slots.single.fireAt, DateTime(2026, 10, 6, 9));
      expect(slots.single.immediate, isFalse);
    });

    test('expired items are not scheduled', () {
      expect(planReminders([item('Leche', '2026-10-05')], settings, morning), isEmpty);
    });

    test('month precision counts from last day of month', () {
      final slots = planReminders(
        [item('Arroz', '2026-11', precision: ExpiryPrecision.month)],
        settings,
        morning,
      );
      expect(slots.single.fireAt, DateTime(2026, 11, 28, 9));
    });

    test('lead 0 fires on the expiry day', () {
      final s = settings.copyWith(generalLeadDays: 0);
      final slots = planReminders([item('Pan', '2026-10-09')], s, morning);
      expect(slots.single.fireAt, DateTime(2026, 10, 9, 9));
    });

    test('custom notify time is respected', () {
      final s = settings.copyWith(notifyHour: 20, notifyMinute: 30);
      final slots = planReminders([item('Pan', '2026-10-10')], s, morning);
      expect(slots.single.fireAt, DateTime(2026, 10, 8, 20, 30));
    });

    test('lead crossing a month boundary', () {
      final s = settings.copyWith(generalLeadDays: 10);
      final slots = planReminders([item('Queso', '2026-11-03')], s, morning);
      expect(slots.single.fireAt, DateTime(2026, 10, 24, 9));
    });
  });

  group('planReminders — rules', () {
    test('category off is not scheduled', () {
      final s = settings.withRule(Category.pantry, const CategoryReminderRule.off());
      final slots = planReminders(
        [
          item('Arroz', '2026-10-20', category: Category.pantry),
          item('Pollo', '2026-10-20', category: Category.meat),
        ],
        s,
        morning,
      );
      expect(slots.single.items.map((i) => i.name), ['Pollo']);
    });

    test('globally disabled schedules nothing', () {
      final s = settings.copyWith(enabled: false);
      expect(planReminders([item('Leche', '2026-10-10')], s, morning), isEmpty);
    });

    test('custom category lead is used', () {
      final s = settings.withRule(Category.meat, const CategoryReminderRule.custom(5));
      final slots = planReminders(
        [item('Pollo', '2026-10-20', category: Category.meat)],
        s,
        morning,
      );
      expect(slots.single.fireAt, DateTime(2026, 10, 15, 9));
    });
  });

  group('planReminders — grouping', () {
    test('items whose reminder falls on the same day share one slot', () {
      final s = settings.withRule(Category.meat, const CategoryReminderRule.custom(0));
      final slots = planReminders(
        [
          item('Yogur', '2026-10-12'), // 2 days → 10-10
          item('Pollo', '2026-10-10', category: Category.meat), // 0 days → 10-10
          item('Queso', '2026-10-15'), // → 10-13
        ],
        s,
        morning,
      );
      expect(slots, hasLength(2));
      expect(slots[0].fireAt, DateTime(2026, 10, 10, 9));
      // Sorted by expiry inside the slot.
      expect(slots[0].items.map((i) => i.name), ['Pollo', 'Yogur']);
      expect(slots[1].items.map((i) => i.name), ['Queso']);
    });

    test('slots are ordered by time, immediate first', () {
      final slots = planReminders(
        [
          item('Lejano', '2026-10-20'),
          item('Hoy', '2026-10-06'),
          item('Mañana', '2026-10-07'),
        ],
        settings,
        evening,
      );
      expect(slots.map((s) => s.immediate), [true, false, false]);
      expect(slots[1].fireAt, DateTime(2026, 10, 7, 9));
      expect(slots[2].fireAt, DateTime(2026, 10, 18, 9));
    });

    test('several immediate items are grouped together', () {
      final slots = planReminders(
        [item('A', '2026-10-06'), item('B', '2026-10-06')],
        settings,
        evening,
      );
      expect(slots, hasLength(1));
      expect(slots.single.items, hasLength(2));
    });

    test('caps the number of slots, keeping the nearest', () {
      final items = [
        for (var d = 0; d < 40; d++)
          item('I$d', _ymd(DateTime(2026, 10, 10 + d))),
      ];
      final slots = planReminders(items, settings, morning);
      expect(slots, hasLength(maxReminderSlots));
      expect(slots.first.fireAt, DateTime(2026, 10, 8, 9));
      expect(slots.last.items.single.name, 'I${maxReminderSlots - 1}');
    });
  });

  group('already notified items', () {
    test('are skipped instead of being treated as late', () {
      final leche = item('Leche', '2026-10-08'); // target 10-06 09:00, delivered
      final slots = planReminders(
        [leche, item('Pan', '2026-10-10')],
        settings,
        evening,
        alreadyNotified: {leche.id!},
      );
      expect(slots.single.items.map((i) => i.name), ['Pan']);
    });

    test('notifiedItemIds: fired entry with same expiry counts', () {
      final leche = item('Leche', '2026-10-08');
      final log = {
        leche.id!: ReminderLogEntry(
          fireAt: DateTime(2026, 10, 6, 9),
          expiryKey: reminderExpiryKey(leche),
        ),
      };
      expect(notifiedItemIds([leche], log, evening), {leche.id});
    });

    test('notifiedItemIds: pending entry does not count', () {
      final leche = item('Leche', '2026-10-08');
      final log = {
        leche.id!: ReminderLogEntry(
          fireAt: DateTime(2026, 10, 6, 9),
          expiryKey: reminderExpiryKey(leche),
        ),
      };
      expect(notifiedItemIds([leche], log, morning), isEmpty);
    });

    test('notifiedItemIds: edited expiry is reminded again', () {
      final before = item('Leche', '2026-10-08');
      final after = before.copyWith(expiryValue: '2026-10-20');
      final log = {
        before.id!: ReminderLogEntry(
          fireAt: DateTime(2026, 10, 6, 9),
          expiryKey: reminderExpiryKey(before),
        ),
      };
      expect(notifiedItemIds([after], log, evening), isEmpty);
    });
  });

  group('reminderNotificationId', () {
    test('stable per day, distinct across days, immediate reserved', () {
      final a = planReminders([item('A', '2026-10-10')], settings, morning).single;
      final b = planReminders([item('B', '2026-10-10')], settings, morning).single;
      final c = planReminders([item('C', '2026-10-11')], settings, morning).single;
      final now = planReminders([item('D', '2026-10-06')], settings, evening).single;

      expect(reminderNotificationId(a), reminderNotificationId(b));
      expect(reminderNotificationId(a), isNot(reminderNotificationId(c)));
      expect(reminderNotificationId(now), immediateReminderNotificationId);
      expect(reminderNotificationId(a), isPositive);
    });
  });
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
