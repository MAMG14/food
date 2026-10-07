import 'expiry.dart';
import 'models/food_item.dart';

/// Visual urgency of an item's expiry relative to [today] (spec 002).
enum ExpiryUrgency {
  /// effective < today
  critical,

  /// 0–2 days remaining (inclusive)
  high,

  /// 3+ days remaining
  normal,
}

/// Whole days from [today] (day-only) until effective expiry.
///
/// Negative means already expired.
int daysUntilExpiry(FoodItem item, DateTime today) {
  final effective = effectiveExpiryDate(item.expiryPrecision, item.expiryValue);
  return dateOnly(effective).difference(dateOnly(today)).inDays;
}

/// Urgency band for [item] on calendar day [today].
ExpiryUrgency expiryUrgency(FoodItem item, DateTime today) {
  final days = daysUntilExpiry(item, today);
  if (days < 0) return ExpiryUrgency.critical;
  if (days <= 2) return ExpiryUrgency.high;
  return ExpiryUrgency.normal;
}
