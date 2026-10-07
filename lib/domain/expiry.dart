import 'models/enums.dart';
import 'models/food_item.dart';

/// Truncates [d] to calendar day in local time (no hour/minute).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Effective expiry calendar day for the given precision and value string.
///
/// - [ExpiryPrecision.day]: `YYYY-MM-DD` → that local day.
/// - [ExpiryPrecision.month]: `YYYY-MM` → last day of that month (local).
DateTime effectiveExpiryDate(ExpiryPrecision precision, String value) {
  switch (precision) {
    case ExpiryPrecision.day:
      final parts = value.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      return DateTime(y, m, d);
    case ExpiryPrecision.month:
      final parts = value.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      // Day 0 of next month = last day of [m].
      return DateTime(y, m + 1, 0);
  }
}

/// Whether [item] is expired relative to [today] (local calendar day).
///
/// Expired when effective expiry date is strictly before today (day-only).
bool isExpired(FoodItem item, DateTime today) {
  final effective = effectiveExpiryDate(item.expiryPrecision, item.expiryValue);
  return effective.isBefore(dateOnly(today));
}

/// Whether [item] is still active (effective expiry ≥ today, day-only).
bool isActive(FoodItem item, DateTime today) => !isExpired(item, today);

/// Filters [items] to the given [InventoryView] relative to [today].
List<FoodItem> filterByView(
  List<FoodItem> items,
  InventoryView view,
  DateTime today,
) {
  return items.where((item) {
    return switch (view) {
      InventoryView.active => isActive(item, today),
      InventoryView.expired => isExpired(item, today),
    };
  }).toList();
}

/// Returns a new list sorted by [mode].
///
/// - [SortMode.name]: case-insensitive name ascending.
/// - [SortMode.expiry]: effective expiry date ascending.
List<FoodItem> sortItems(
  List<FoodItem> items,
  SortMode mode,
  DateTime today,
) {
  final sorted = List<FoodItem>.of(items);
  switch (mode) {
    case SortMode.name:
      sorted.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    case SortMode.expiry:
      sorted.sort((a, b) {
        final aDate = effectiveExpiryDate(a.expiryPrecision, a.expiryValue);
        final bDate = effectiveExpiryDate(b.expiryPrecision, b.expiryValue);
        return aDate.compareTo(bDate);
      });
  }
  return sorted;
}
