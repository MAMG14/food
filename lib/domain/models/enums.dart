/// Precision of an expiry date: exact calendar day or month/year only.
enum ExpiryPrecision {
  day,
  month,
}

/// Fixed quantity units for food items.
enum Unit {
  pz,
  kg,
  g,
  L,
  ml,
}

/// Fixed food categories.
enum Category {
  dairy,
  meat,
  vegetables,
  pantry,
  other,
}

/// Where the item is stored.
enum StorageLocation {
  fridge,
  pantry,
  other,
}

/// How the inventory list is sorted.
enum SortMode {
  name,
  expiry,
}

/// Which inventory list the user is viewing.
enum InventoryView {
  active,
  expired,
}
