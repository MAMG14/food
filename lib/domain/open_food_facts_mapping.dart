import 'package:food/domain/models/enums.dart';

/// Parsed quantity from an Open Food Facts `quantity` string.
class ParsedQuantity {
  const ParsedQuantity({required this.quantity, required this.unit});

  final double quantity;
  final Unit unit;
}

/// Draft fields for confirm-after-scan (before expiry / user edits).
class OffProductDraft {
  const OffProductDraft({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.imageUrl,
    this.barcode,
  });

  final String name;
  final double quantity;
  final Unit unit;
  final Category category;
  final String? imageUrl;
  final String? barcode;
}

/// Minimal OFF product payload used for mapping (no HTTP).
class OffProductInput {
  const OffProductInput({
    this.productName,
    this.brands,
    this.quantity,
    this.categoriesTags = const [],
    this.imageUrl,
    this.barcode,
  });

  final String? productName;
  final String? brands;
  final String? quantity;
  final List<String> categoriesTags;
  final String? imageUrl;
  final String? barcode;
}

/// Parses strings like `155 g`, `1 L`, `500ml`. Returns null if unusable.
ParsedQuantity? parseOffQuantity(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final match = RegExp(
    r'^([\d]+(?:[.,]\d+)?)\s*(kg|g|ml|l|pz|pcs?|pieces?)?\b',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (match == null) return null;

  final numberRaw = match.group(1)!.replaceAll(',', '.');
  final quantity = double.tryParse(numberRaw);
  if (quantity == null || quantity <= 0) return null;

  final unitRaw = match.group(2)?.toLowerCase();
  final unit = switch (unitRaw) {
    'kg' => Unit.kg,
    'g' => Unit.g,
    'ml' => Unit.ml,
    'l' => Unit.L,
    'pz' || 'pc' || 'pcs' || 'piece' || 'pieces' => Unit.pz,
    null => null,
    _ => null,
  };
  if (unit == null) return null;

  return ParsedQuantity(quantity: quantity, unit: unit);
}

/// Maps OFF `categories_tags` to a fixed [Category]; unknown → [Category.other].
Category mapOffCategories(List<String> tags) {
  final normalized = tags.map((t) => t.toLowerCase()).toList();

  bool hasAny(List<String> needles) =>
      normalized.any((tag) => needles.any(tag.contains));

  if (hasAny([
    'en:dairy',
    'en:milks',
    'en:cheeses',
    'en:yogurts',
    'en:cream',
    'dairy',
    'milk',
    'cheese',
    'yogurt',
  ])) {
    return Category.dairy;
  }
  if (hasAny([
    'en:meats',
    'en:meat',
    'en:poultry',
    'en:fish',
    'en:seafood',
    'meat',
    'poultry',
    'fish',
  ])) {
    return Category.meat;
  }
  if (hasAny([
    'en:vegetables',
    'en:fruits',
    'en:fresh-vegetables',
    'en:fresh-fruits',
    'vegetable',
    'fruit',
  ])) {
    return Category.vegetables;
  }
  if (hasAny([
    'en:cereals',
    'en:pastas',
    'en:rices',
    'en:breads',
    'en:canned',
    'en:plant-based-foods',
    'pasta',
    'rice',
    'cereal',
    'bread',
    'noodle',
  ])) {
    return Category.pantry;
  }
  return Category.other;
}

/// Builds a display name; null if [productName] is empty after trim.
String? buildProductName(String? productName, String? brands) {
  final name = productName?.trim() ?? '';
  if (name.isEmpty) return null;

  final brand = brands?.trim() ?? '';
  if (brand.isEmpty) return name;

  final nameLower = name.toLowerCase();
  final brandLower = brand.toLowerCase();
  if (nameLower.contains(brandLower)) return name;

  return '$name — $brand';
}

/// Maps an OFF product to a draft, or null if there is no usable name (no match).
OffProductDraft? offProductToDraft(OffProductInput input) {
  final name = buildProductName(input.productName, input.brands);
  if (name == null) return null;

  final parsed = parseOffQuantity(input.quantity);
  return OffProductDraft(
    name: name,
    quantity: parsed?.quantity ?? 1,
    unit: parsed?.unit ?? Unit.pz,
    category: mapOffCategories(input.categoriesTags),
    imageUrl: input.imageUrl?.trim().isEmpty == true
        ? null
        : input.imageUrl?.trim(),
    barcode: input.barcode?.trim().isEmpty == true
        ? null
        : input.barcode?.trim(),
  );
}
