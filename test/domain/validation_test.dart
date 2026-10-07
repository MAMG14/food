import 'package:flutter_test/flutter_test.dart';
import 'package:food/domain/models/enums.dart';
import 'package:food/domain/validation.dart';

void main() {
  group('validateFoodItemInput — name (RF-2)', () {
    test('empty name is invalid', () {
      final result = validateFoodItemInput(
        name: '',
        quantity: 1,
        expiryPrecision: ExpiryPrecision.day,
        expiryValue: '2026-03-15',
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors,
        contains(
          const FieldValidationError(
            ValidationField.name,
            ValidationErrorCode.nameEmpty,
          ),
        ),
      );
    });

    test('whitespace-only name is invalid', () {
      final result = validateFoodItemInput(
        name: '   ',
        quantity: 1,
        expiryPrecision: ExpiryPrecision.day,
        expiryValue: '2026-03-15',
      );

      expect(result.isValid, isFalse);
      expect(
        result.errorsFor(ValidationField.name).single.code,
        ValidationErrorCode.nameEmpty,
      );
    });

    test('trimmed non-empty name is valid', () {
      final result = validateFoodItemInput(
        name: '  leche  ',
        quantity: 1,
        expiryPrecision: ExpiryPrecision.day,
        expiryValue: '2026-03-15',
      );

      expect(result.isValid, isTrue);
    });
  });

  group('validateFoodItemInput — quantity', () {
    test('zero quantity is invalid', () {
      final result = validateFoodItemInput(
        name: 'pan',
        quantity: 0,
        expiryPrecision: ExpiryPrecision.day,
        expiryValue: '2026-03-15',
      );

      expect(result.isValid, isFalse);
      expect(
        result.errorsFor(ValidationField.quantity).single.code,
        ValidationErrorCode.quantityNotPositive,
      );
    });

    test('negative quantity is invalid', () {
      final result = validateFoodItemInput(
        name: 'pan',
        quantity: -1,
        expiryPrecision: ExpiryPrecision.day,
        expiryValue: '2026-03-15',
      );

      expect(result.isValid, isFalse);
      expect(
        result.errorsFor(ValidationField.quantity).single.code,
        ValidationErrorCode.quantityNotPositive,
      );
    });

    test('positive quantity is valid', () {
      final result = validateFoodItemInput(
        name: 'pan',
        quantity: 0.5,
        expiryPrecision: ExpiryPrecision.day,
        expiryValue: '2026-03-15',
      );

      expect(result.isValid, isTrue);
    });
  });

  group('validateFoodItemInput — day expiry (RF-3)', () {
    test('empty day value is incomplete', () {
      final result = validateFoodItemInput(
        name: 'yogur',
        quantity: 1,
        expiryPrecision: ExpiryPrecision.day,
        expiryValue: '',
      );

      expect(
        result.errorsFor(ValidationField.expiry).single.code,
        ValidationErrorCode.expiryIncomplete,
      );
    });

    test('bad day format is invalid', () {
      final result = validateFoodItemInput(
        name: 'yogur',
        quantity: 1,
        expiryPrecision: ExpiryPrecision.day,
        expiryValue: '15/03/2026',
      );

      expect(
        result.errorsFor(ValidationField.expiry).single.code,
        ValidationErrorCode.expiryInvalid,
      );
    });

    test('non-padded day format is invalid', () {
      final result = validateFoodItemInput(
        name: 'yogur',
        quantity: 1,
        expiryPrecision: ExpiryPrecision.day,
        expiryValue: '2026-3-5',
      );

      expect(
        result.errorsFor(ValidationField.expiry).single.code,
        ValidationErrorCode.expiryInvalid,
      );
    });

    test('impossible calendar day is invalid (2026-02-31)', () {
      final result = validateFoodItemInput(
        name: 'yogur',
        quantity: 1,
        expiryPrecision: ExpiryPrecision.day,
        expiryValue: '2026-02-31',
      );

      expect(
        result.errorsFor(ValidationField.expiry).single.code,
        ValidationErrorCode.expiryInvalid,
      );
    });

    test('valid day is accepted', () {
      final result = validateFoodItemInput(
        name: 'yogur',
        quantity: 1,
        expiryPrecision: ExpiryPrecision.day,
        expiryValue: '2026-02-28',
      );

      expect(result.isValid, isTrue);
    });

    test('leap day is accepted', () {
      final result = validateFoodItemInput(
        name: 'yogur',
        quantity: 1,
        expiryPrecision: ExpiryPrecision.day,
        expiryValue: '2024-02-29',
      );

      expect(result.isValid, isTrue);
    });
  });

  group('validateFoodItemInput — month expiry (RF-3)', () {
    test('empty month value is incomplete', () {
      final result = validateFoodItemInput(
        name: 'arroz',
        quantity: 1,
        expiryPrecision: ExpiryPrecision.month,
        expiryValue: '  ',
      );

      expect(
        result.errorsFor(ValidationField.expiry).single.code,
        ValidationErrorCode.expiryIncomplete,
      );
    });

    test('bad month format is invalid', () {
      final result = validateFoodItemInput(
        name: 'arroz',
        quantity: 1,
        expiryPrecision: ExpiryPrecision.month,
        expiryValue: '2026/02',
      );

      expect(
        result.errorsFor(ValidationField.expiry).single.code,
        ValidationErrorCode.expiryInvalid,
      );
    });

    test('month out of range is invalid', () {
      final result = validateFoodItemInput(
        name: 'arroz',
        quantity: 1,
        expiryPrecision: ExpiryPrecision.month,
        expiryValue: '2026-13',
      );

      expect(
        result.errorsFor(ValidationField.expiry).single.code,
        ValidationErrorCode.expiryInvalid,
      );
    });

    test('day-shaped value is invalid for month precision', () {
      final result = validateFoodItemInput(
        name: 'arroz',
        quantity: 1,
        expiryPrecision: ExpiryPrecision.month,
        expiryValue: '2026-03-15',
      );

      expect(
        result.errorsFor(ValidationField.expiry).single.code,
        ValidationErrorCode.expiryInvalid,
      );
    });

    test('valid month is accepted', () {
      final result = validateFoodItemInput(
        name: 'arroz',
        quantity: 2,
        expiryPrecision: ExpiryPrecision.month,
        expiryValue: '2026-02',
      );

      expect(result.isValid, isTrue);
    });
  });

  group('validateFoodItemInput — multiple errors', () {
    test('collects name, quantity and expiry errors together', () {
      final result = validateFoodItemInput(
        name: '',
        quantity: 0,
        expiryPrecision: ExpiryPrecision.day,
        expiryValue: '2026-02-31',
      );

      expect(result.ok, isFalse);
      expect(result.errors, hasLength(3));
      expect(
        result.errors.map((e) => e.field),
        containsAll([
          ValidationField.name,
          ValidationField.quantity,
          ValidationField.expiry,
        ]),
      );
    });
  });
}
