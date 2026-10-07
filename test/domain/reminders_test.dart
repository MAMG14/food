import 'package:flutter_test/flutter_test.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/reminder_settings.dart';
import 'package:food/domain/reminders.dart';

void main() {
  group('ReminderSettings defaults (spec 003)', () {
    const defaults = ReminderSettings.defaults;

    test('enabled, 2 days ahead, at 09:00, permission not asked yet', () {
      expect(defaults.enabled, isTrue);
      expect(defaults.generalLeadDays, 2);
      expect(defaults.notifyHour, 9);
      expect(defaults.notifyMinute, 0);
      expect(defaults.permissionAsked, isFalse);
    });

    test('every category uses the general rule', () {
      for (final category in Category.values) {
        expect(defaults.ruleFor(category), const CategoryReminderRule.useGeneral());
      }
    });
  });

  group('allowedLeadDays', () {
    test('is the fixed list from the spec, ascending', () {
      expect(allowedLeadDays, [0, 1, 2, 3, 5, 7, 10, 14, 21, 30]);
    });

    test('isAllowedLeadDays accepts listed values only', () {
      expect(isAllowedLeadDays(0), isTrue);
      expect(isAllowedLeadDays(30), isTrue);
      expect(isAllowedLeadDays(4), isFalse);
      expect(isAllowedLeadDays(-1), isFalse);
      expect(isAllowedLeadDays(31), isFalse);
    });
  });

  group('effectiveLeadDays', () {
    test('category without own rule uses the general lead', () {
      const settings = ReminderSettings.defaults;
      expect(effectiveLeadDays(Category.dairy, settings), 2);
    });

    test('general lead change applies to categories using general', () {
      final settings = ReminderSettings.defaults.copyWith(generalLeadDays: 7);
      expect(effectiveLeadDays(Category.pantry, settings), 7);
    });

    test('custom category rule overrides the general lead', () {
      final settings = ReminderSettings.defaults.withRule(
        Category.meat,
        const CategoryReminderRule.custom(1),
      );
      expect(effectiveLeadDays(Category.meat, settings), 1);
      expect(effectiveLeadDays(Category.dairy, settings), 2);
    });

    test('custom rule of 0 days means same day, not "no reminder"', () {
      final settings = ReminderSettings.defaults.withRule(
        Category.vegetables,
        const CategoryReminderRule.custom(0),
      );
      expect(effectiveLeadDays(Category.vegetables, settings), 0);
    });

    test('off category rule means no reminder', () {
      final settings = ReminderSettings.defaults.withRule(
        Category.pantry,
        const CategoryReminderRule.off(),
      );
      expect(effectiveLeadDays(Category.pantry, settings), isNull);
      expect(effectiveLeadDays(Category.meat, settings), 2);
    });

    test('globally disabled means no reminder for any category', () {
      final settings = ReminderSettings.defaults
          .copyWith(enabled: false)
          .withRule(Category.meat, const CategoryReminderRule.custom(3));
      for (final category in Category.values) {
        expect(effectiveLeadDays(category, settings), isNull);
      }
    });

    test('withRule back to useGeneral restores the general lead', () {
      final settings = ReminderSettings.defaults
          .withRule(Category.meat, const CategoryReminderRule.off())
          .withRule(Category.meat, const CategoryReminderRule.useGeneral());
      expect(effectiveLeadDays(Category.meat, settings), 2);
    });
  });
}
