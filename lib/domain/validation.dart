import 'models/enums.dart';

/// Field that failed validation.
enum ValidationField {
  name,
  quantity,
  expiry,
}

/// Stable error codes for UI i18n mapping (English identifiers).
enum ValidationErrorCode {
  nameEmpty,
  quantityNotPositive,
  expiryIncomplete,
  expiryInvalid,
}

/// Single field-level validation error.
class FieldValidationError {
  const FieldValidationError(this.field, this.code);

  final ValidationField field;
  final ValidationErrorCode code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldValidationError &&
          field == other.field &&
          code == other.code;

  @override
  int get hashCode => Object.hash(field, code);

  @override
  String toString() => 'FieldValidationError($field, $code)';
}

/// Result of validating food item input.
class ValidationResult {
  const ValidationResult.ok() : errors = const [];

  /// One or more field errors.
  const ValidationResult.invalid(this.errors);

  final List<FieldValidationError> errors;

  bool get isValid => errors.isEmpty;

  bool get ok => isValid;

  /// Errors for a specific [field], if any.
  Iterable<FieldValidationError> errorsFor(ValidationField field) =>
      errors.where((e) => e.field == field);
}

final _dayPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
final _monthPattern = RegExp(r'^(\d{4})-(\d{2})$');

/// Validates create/edit input for a food item (RF-2, RF-3, quantity > 0).
///
/// Does not persist or touch UI. Error codes are stable English enums for i18n.
ValidationResult validateFoodItemInput({
  required String name,
  required double quantity,
  required ExpiryPrecision expiryPrecision,
  required String expiryValue,
}) {
  final errors = <FieldValidationError>[];

  if (name.trim().isEmpty) {
    errors.add(
      const FieldValidationError(
        ValidationField.name,
        ValidationErrorCode.nameEmpty,
      ),
    );
  }

  if (!(quantity > 0)) {
    errors.add(
      const FieldValidationError(
        ValidationField.quantity,
        ValidationErrorCode.quantityNotPositive,
      ),
    );
  }

  final expiryError = _validateExpiry(expiryPrecision, expiryValue);
  if (expiryError != null) {
    errors.add(expiryError);
  }

  if (errors.isEmpty) {
    return const ValidationResult.ok();
  }
  return ValidationResult.invalid(errors);
}

FieldValidationError? _validateExpiry(
  ExpiryPrecision precision,
  String value,
) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return const FieldValidationError(
      ValidationField.expiry,
      ValidationErrorCode.expiryIncomplete,
    );
  }

  switch (precision) {
    case ExpiryPrecision.day:
      return _validateDayExpiry(trimmed);
    case ExpiryPrecision.month:
      return _validateMonthExpiry(trimmed);
  }
}

FieldValidationError? _validateDayExpiry(String value) {
  final match = _dayPattern.firstMatch(value);
  if (match == null) {
    return const FieldValidationError(
      ValidationField.expiry,
      ValidationErrorCode.expiryInvalid,
    );
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);

  if (month < 1 || month > 12) {
    return const FieldValidationError(
      ValidationField.expiry,
      ValidationErrorCode.expiryInvalid,
    );
  }

  // Dart DateTime overflows invalid days; require exact calendar match.
  final constructed = DateTime(year, month, day);
  if (constructed.year != year ||
      constructed.month != month ||
      constructed.day != day) {
    return const FieldValidationError(
      ValidationField.expiry,
      ValidationErrorCode.expiryInvalid,
    );
  }

  return null;
}

FieldValidationError? _validateMonthExpiry(String value) {
  final match = _monthPattern.firstMatch(value);
  if (match == null) {
    return const FieldValidationError(
      ValidationField.expiry,
      ValidationErrorCode.expiryInvalid,
    );
  }

  final month = int.parse(match.group(2)!);
  if (month < 1 || month > 12) {
    return const FieldValidationError(
      ValidationField.expiry,
      ValidationErrorCode.expiryInvalid,
    );
  }

  return null;
}
