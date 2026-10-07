import 'package:flutter_test/flutter_test.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/models/food_item.dart';
import 'package:food/domain/urgency.dart';

FoodItem item({
  required ExpiryPrecision precision,
  required String value,
}) {
  return FoodItem(
    name: 'Test',
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

  group('expiryUrgency', () {
    test('critical when effective before today', () {
      final i = item(precision: ExpiryPrecision.day, value: '2026-10-05');
      expect(expiryUrgency(i, today), ExpiryUrgency.critical);
      expect(daysUntilExpiry(i, today), -1);
    });

    test('high when expires today (0 days)', () {
      final i = item(precision: ExpiryPrecision.day, value: '2026-10-06');
      expect(expiryUrgency(i, today), ExpiryUrgency.high);
      expect(daysUntilExpiry(i, today), 0);
    });

    test('high when expires in 2 days', () {
      final i = item(precision: ExpiryPrecision.day, value: '2026-10-08');
      expect(expiryUrgency(i, today), ExpiryUrgency.high);
      expect(daysUntilExpiry(i, today), 2);
    });

    test('normal when expires in 3 days', () {
      final i = item(precision: ExpiryPrecision.day, value: '2026-10-09');
      expect(expiryUrgency(i, today), ExpiryUrgency.normal);
      expect(daysUntilExpiry(i, today), 3);
    });

    test('month precision uses last day of month', () {
      // October 2026 ends on 31st → 25 days from Oct 6 → normal
      final i = item(precision: ExpiryPrecision.month, value: '2026-10');
      expect(daysUntilExpiry(i, today), 25);
      expect(expiryUrgency(i, today), ExpiryUrgency.normal);
    });

    test('month already past is critical', () {
      final i = item(precision: ExpiryPrecision.month, value: '2026-09');
      expect(expiryUrgency(i, today), ExpiryUrgency.critical);
    });
  });
}
