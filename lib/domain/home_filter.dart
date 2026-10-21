import 'models/food_item.dart';
import 'urgency.dart';

/// Home summary filter (spec 004), mapped from [ExpiryUrgency].
enum HomeFilter {
  /// Active items with normal urgency (3+ days).
  optimal,

  /// Active items with high urgency (0–2 days).
  soon,

  /// Expired items (critical urgency).
  expired,
}

/// Counts of items in each [HomeFilter] bucket for calendar day [today].
class HomeFilterCounts {
  const HomeFilterCounts({
    required this.optimal,
    required this.soon,
    required this.expired,
  });

  final int optimal;
  final int soon;
  final int expired;

  int countFor(HomeFilter filter) {
    return switch (filter) {
      HomeFilter.optimal => optimal,
      HomeFilter.soon => soon,
      HomeFilter.expired => expired,
    };
  }
}

/// Maps urgency to the Home filter bucket.
HomeFilter homeFilterForUrgency(ExpiryUrgency urgency) {
  return switch (urgency) {
    ExpiryUrgency.critical => HomeFilter.expired,
    ExpiryUrgency.high => HomeFilter.soon,
    ExpiryUrgency.normal => HomeFilter.optimal,
  };
}

/// How many items fall into each Home filter for [today].
HomeFilterCounts countByHomeFilter(Iterable<FoodItem> items, DateTime today) {
  var optimal = 0;
  var soon = 0;
  var expired = 0;
  for (final item in items) {
    switch (homeFilterForUrgency(expiryUrgency(item, today))) {
      case HomeFilter.optimal:
        optimal++;
      case HomeFilter.soon:
        soon++;
      case HomeFilter.expired:
        expired++;
    }
  }
  return HomeFilterCounts(optimal: optimal, soon: soon, expired: expired);
}

/// Items belonging to [filter] on calendar day [today].
List<FoodItem> itemsForHomeFilter(
  Iterable<FoodItem> items,
  HomeFilter filter,
  DateTime today,
) {
  return items
      .where(
        (item) => homeFilterForUrgency(expiryUrgency(item, today)) == filter,
      )
      .toList(growable: false);
}

/// Default filter when opening Home: prefer [HomeFilter.optimal] if it has
/// items; otherwise the first filter in order optimal → soon → expired with
/// items; if all empty, [HomeFilter.optimal].
HomeFilter defaultHomeFilter(HomeFilterCounts counts) {
  if (counts.optimal > 0) return HomeFilter.optimal;
  if (counts.soon > 0) return HomeFilter.soon;
  if (counts.expired > 0) return HomeFilter.expired;
  return HomeFilter.optimal;
}
