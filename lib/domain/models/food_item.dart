import 'enums.dart';

/// Domain model for a food inventory item.
class FoodItem {
  const FoodItem({
    this.id,
    required this.name,
    required this.expiryPrecision,
    required this.expiryValue,
    required this.quantity,
    required this.unit,
    required this.category,
    this.notes,
    required this.location,
    this.barcode,
    this.imagePath,
  });

  /// Local database id; null before the item is persisted.
  final int? id;

  final String name;

  final ExpiryPrecision expiryPrecision;

  /// Calendar value as `YYYY-MM-DD` (day) or `YYYY-MM` (month).
  final String expiryValue;

  final double quantity;

  final Unit unit;

  final Category category;

  final String? notes;

  final StorageLocation location;

  /// EAN/UPC when the item came from a barcode scan (optional).
  final String? barcode;

  /// Absolute local path to a downloaded product image (optional).
  final String? imagePath;

  FoodItem copyWith({
    int? id,
    String? name,
    ExpiryPrecision? expiryPrecision,
    String? expiryValue,
    double? quantity,
    Unit? unit,
    Category? category,
    String? notes,
    StorageLocation? location,
    String? barcode,
    String? imagePath,
    bool clearNotes = false,
    bool clearBarcode = false,
    bool clearImagePath = false,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      expiryPrecision: expiryPrecision ?? this.expiryPrecision,
      expiryValue: expiryValue ?? this.expiryValue,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      notes: clearNotes ? null : (notes ?? this.notes),
      location: location ?? this.location,
      barcode: clearBarcode ? null : (barcode ?? this.barcode),
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
    );
  }
}
