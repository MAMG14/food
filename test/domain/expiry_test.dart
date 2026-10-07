import 'package:flutter_test/flutter_test.dart';
import 'package:food/domain/expiry.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/food_item.dart';

FoodItem _item({
  required String name,
  required ExpiryPrecision precision,
  required String value,
}) {
  return FoodItem(
    name: name,
    expiryPrecision: precision,
    expiryValue: value,
    quantity: 1,
    unit: Unit.pz,
    category: Category.other,
    location: StorageLocation.other,
  );
}

void main() {
  group('dateOnly', () {
    test('strips time components', () {
      final withTime = DateTime(2026, 3, 15, 14, 30, 45);
      expect(dateOnly(withTime), DateTime(2026, 3, 15));
    });
  });

  group('effectiveExpiryDate', () {
    test('day precision uses exact calendar day', () {
      expect(
        effectiveExpiryDate(ExpiryPrecision.day, '2026-03-15'),
        DateTime(2026, 3, 15),
      );
    });

    test('month precision uses last day of month (non-leap Feb)', () {
      expect(
        effectiveExpiryDate(ExpiryPrecision.month, '2026-02'),
        DateTime(2026, 2, 28),
      );
    });

    test('month precision uses last day of month (leap Feb)', () {
      expect(
        effectiveExpiryDate(ExpiryPrecision.month, '2024-02'),
        DateTime(2024, 2, 29),
      );
    });

    test('month precision for 31-day month', () {
      expect(
        effectiveExpiryDate(ExpiryPrecision.month, '2026-01'),
        DateTime(2026, 1, 31),
      );
    });
  });

  group('isExpired / isActive', () {
    final today = DateTime(2026, 3, 15);

    test('effective == today → active, not expired', () {
      final item = _item(
        name: 'Milk',
        precision: ExpiryPrecision.day,
        value: '2026-03-15',
      );
      expect(isExpired(item, today), isFalse);
      expect(isActive(item, today), isTrue);
    });

    test('effective > today → active', () {
      final item = _item(
        name: 'Cheese',
        precision: ExpiryPrecision.day,
        value: '2026-03-16',
      );
      expect(isActive(item, today), isTrue);
      expect(isExpired(item, today), isFalse);
    });

    test('effective < today → expired', () {
      final item = _item(
        name: 'Yogurt',
        precision: ExpiryPrecision.day,
        value: '2026-03-14',
      );
      expect(isExpired(item, today), isTrue);
      expect(isActive(item, today), isFalse);
    });

    test('month boundary: last day of month == today → active', () {
      final lastDay = DateTime(2026, 2, 28);
      final item = _item(
        name: 'Pantry',
        precision: ExpiryPrecision.month,
        value: '2026-02',
      );
      expect(isActive(item, lastDay), isTrue);
      expect(isExpired(item, lastDay), isFalse);
    });

    test('month boundary: day after last day → expired', () {
      final dayAfter = DateTime(2026, 3, 1);
      final item = _item(
        name: 'Pantry',
        precision: ExpiryPrecision.month,
        value: '2026-02',
      );
      expect(isExpired(item, dayAfter), isTrue);
      expect(isActive(item, dayAfter), isFalse);
    });

    test('today with time-of-day still compares day-only', () {
      final todayWithTime = DateTime(2026, 3, 15, 23, 59);
      final item = _item(
        name: 'Milk',
        precision: ExpiryPrecision.day,
        value: '2026-03-15',
      );
      expect(isActive(item, todayWithTime), isTrue);
    });
  });

  group('filterByView', () {
    final today = DateTime(2026, 3, 15);
    final activeItem = _item(
      name: 'Active',
      precision: ExpiryPrecision.day,
      value: '2026-03-20',
    );
    final boundaryItem = _item(
      name: 'Boundary',
      precision: ExpiryPrecision.day,
      value: '2026-03-15',
    );
    final expiredItem = _item(
      name: 'Expired',
      precision: ExpiryPrecision.day,
      value: '2026-03-10',
    );
    final items = [activeItem, boundaryItem, expiredItem];

    test('filters active (includes effective == today)', () {
      final result = filterByView(items, InventoryView.active, today);
      expect(result.map((e) => e.name), ['Active', 'Boundary']);
    });

    test('filters expired', () {
      final result = filterByView(items, InventoryView.expired, today);
      expect(result.map((e) => e.name), ['Expired']);
    });
  });

  group('sortItems', () {
    final today = DateTime(2026, 3, 15);

    test('sorts by name case-insensitively', () {
      final items = [
        _item(
          name: 'banana',
          precision: ExpiryPrecision.day,
          value: '2026-04-01',
        ),
        _item(
          name: 'Apple',
          precision: ExpiryPrecision.day,
          value: '2026-05-01',
        ),
        _item(
          name: 'Cherry',
          precision: ExpiryPrecision.day,
          value: '2026-03-20',
        ),
      ];
      final sorted = sortItems(items, SortMode.name, today);
      expect(sorted.map((e) => e.name), ['Apple', 'banana', 'Cherry']);
    });

    test('sorts by effective expiry ascending', () {
      final items = [
        _item(
          name: 'Late day',
          precision: ExpiryPrecision.day,
          value: '2026-04-15',
        ),
        _item(
          name: 'Month Feb',
          precision: ExpiryPrecision.month,
          value: '2026-02',
        ),
        _item(
          name: 'Early day',
          precision: ExpiryPrecision.day,
          value: '2026-03-01',
        ),
      ];
      final sorted = sortItems(items, SortMode.expiry, today);
      expect(sorted.map((e) => e.name), [
        'Month Feb', // 2026-02-28
        'Early day', // 2026-03-01
        'Late day', // 2026-04-15
      ]);
    });
  });
}
