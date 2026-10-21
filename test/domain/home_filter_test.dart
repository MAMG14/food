import 'package:flutter_test/flutter_test.dart';
import 'package:food/domain/home_filter.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/food_item.dart';

FoodItem item({
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
  final today = DateTime(2026, 10, 6);

  final optimal = item(
    name: 'Optimal',
    precision: ExpiryPrecision.day,
    value: '2026-10-09',
  );
  final soon = item(
    name: 'Soon',
    precision: ExpiryPrecision.day,
    value: '2026-10-07',
  );
  final expired = item(
    name: 'Expired',
    precision: ExpiryPrecision.day,
    value: '2026-10-05',
  );

  group('countByHomeFilter', () {
    test('all zero when empty', () {
      final counts = countByHomeFilter(const [], today);
      expect(counts.optimal, 0);
      expect(counts.soon, 0);
      expect(counts.expired, 0);
    });

    test('partitions mixed inventory', () {
      final counts = countByHomeFilter([optimal, soon, expired, soon], today);
      expect(counts.optimal, 1);
      expect(counts.soon, 2);
      expect(counts.expired, 1);
      expect(counts.countFor(HomeFilter.soon), 2);
    });
  });

  group('itemsForHomeFilter', () {
    test('returns only matching bucket', () {
      final all = [optimal, soon, expired];
      expect(
        itemsForHomeFilter(all, HomeFilter.optimal, today).map((e) => e.name),
        ['Optimal'],
      );
      expect(
        itemsForHomeFilter(all, HomeFilter.soon, today).map((e) => e.name),
        ['Soon'],
      );
      expect(
        itemsForHomeFilter(all, HomeFilter.expired, today).map((e) => e.name),
        ['Expired'],
      );
    });
  });

  group('defaultHomeFilter', () {
    test('empty → optimal', () {
      expect(
        defaultHomeFilter(const HomeFilterCounts(optimal: 0, soon: 0, expired: 0)),
        HomeFilter.optimal,
      );
    });

    test('prefers optimal when present', () {
      expect(
        defaultHomeFilter(
          const HomeFilterCounts(optimal: 1, soon: 2, expired: 3),
        ),
        HomeFilter.optimal,
      );
    });

    test('only expired → expired', () {
      expect(
        defaultHomeFilter(
          const HomeFilterCounts(optimal: 0, soon: 0, expired: 4),
        ),
        HomeFilter.expired,
      );
    });

    test('soon without optimal → soon', () {
      expect(
        defaultHomeFilter(
          const HomeFilterCounts(optimal: 0, soon: 1, expired: 2),
        ),
        HomeFilter.soon,
      );
    });
  });
}
