import 'package:flutter_test/flutter_test.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/open_food_facts_mapping.dart';

void main() {
  group('parseOffQuantity', () {
    test('parses grams with space', () {
      final q = parseOffQuantity('155 g');
      expect(q!.quantity, 155);
      expect(q.unit, Unit.g);
    });

    test('parses liters and milliliters without space', () {
      expect(parseOffQuantity('1 L')!.unit, Unit.L);
      expect(parseOffQuantity('500ml')!.quantity, 500);
      expect(parseOffQuantity('500ml')!.unit, Unit.ml);
    });

    test('parses kg and comma decimals', () {
      final q = parseOffQuantity('1,5 kg');
      expect(q!.quantity, 1.5);
      expect(q.unit, Unit.kg);
    });

    test('returns null for empty or unusable', () {
      expect(parseOffQuantity(null), isNull);
      expect(parseOffQuantity(''), isNull);
      expect(parseOffQuantity('a handful'), isNull);
      expect(parseOffQuantity('0 g'), isNull);
    });
  });

  group('mapOffCategories', () {
    test('maps dairy tags', () {
      expect(mapOffCategories(['en:dairy', 'en:milks']), Category.dairy);
    });

    test('maps meat tags', () {
      expect(mapOffCategories(['en:meats', 'en:poultry']), Category.meat);
    });

    test('maps vegetables / fruits', () {
      expect(
        mapOffCategories(['en:vegetables', 'en:fresh-vegetables']),
        Category.vegetables,
      );
    });

    test('maps pantry-like tags', () {
      expect(mapOffCategories(['en:pastas', 'en:noodles']), Category.pantry);
    });

    test('falls back to other', () {
      expect(mapOffCategories([]), Category.other);
      expect(mapOffCategories(['en:beverages']), Category.other);
    });
  });

  group('buildProductName', () {
    test('returns null when name empty', () {
      expect(buildProductName(null, 'Brand'), isNull);
      expect(buildProductName('  ', 'Brand'), isNull);
    });

    test('returns name alone without brands', () {
      expect(buildProductName('Milk', null), 'Milk');
      expect(buildProductName('Milk', ''), 'Milk');
    });

    test('appends brand when not already in name', () {
      expect(buildProductName('Milk', 'Alpura'), 'Milk — Alpura');
    });

    test('does not duplicate brand already in name', () {
      expect(buildProductName('Alpura Milk', 'Alpura'), 'Alpura Milk');
    });
  });

  group('offProductToDraft', () {
    test('returns null without usable name', () {
      expect(
        offProductToDraft(const OffProductInput(productName: '')),
        isNull,
      );
    });

    test('applies defaults when quantity missing', () {
      final draft = offProductToDraft(
        const OffProductInput(
          productName: 'Noodles',
          brands: 'Thai Kitchen',
          categoriesTags: ['en:pastas'],
          imageUrl: 'https://example.com/x.jpg',
          barcode: '123',
        ),
      )!;
      expect(draft.name, 'Noodles — Thai Kitchen');
      expect(draft.quantity, 1);
      expect(draft.unit, Unit.pz);
      expect(draft.category, Category.pantry);
      expect(draft.imageUrl, 'https://example.com/x.jpg');
      expect(draft.barcode, '123');
    });

    test('parses quantity when present', () {
      final draft = offProductToDraft(
        const OffProductInput(
          productName: 'Sugar',
          quantity: '1 kg',
        ),
      )!;
      expect(draft.quantity, 1);
      expect(draft.unit, Unit.kg);
      expect(draft.category, Category.other);
    });
  });
}
