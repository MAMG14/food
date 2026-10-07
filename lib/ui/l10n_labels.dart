import 'package:food/domain/models/enums.dart';
import 'package:food/domain/urgency.dart';
import 'package:food/domain/validation.dart';
import 'package:food/l10n/app_localizations.dart';

extension UnitL10n on Unit {
  String label(AppLocalizations l10n) => switch (this) {
    Unit.pz => l10n.unitPz,
    Unit.kg => l10n.unitKg,
    Unit.g => l10n.unitG,
    Unit.L => l10n.unitL,
    Unit.ml => l10n.unitMl,
  };
}

extension CategoryL10n on Category {
  String label(AppLocalizations l10n) => switch (this) {
    Category.dairy => l10n.categoryDairy,
    Category.meat => l10n.categoryMeat,
    Category.vegetables => l10n.categoryVegetables,
    Category.pantry => l10n.categoryPantry,
    Category.other => l10n.categoryOther,
  };
}

extension StorageLocationL10n on StorageLocation {
  String label(AppLocalizations l10n) => switch (this) {
    StorageLocation.fridge => l10n.locationFridge,
    StorageLocation.pantry => l10n.locationPantry,
    StorageLocation.other => l10n.locationOther,
  };
}

extension ValidationErrorL10n on ValidationErrorCode {
  String label(AppLocalizations l10n) => switch (this) {
    ValidationErrorCode.nameEmpty => l10n.errorNameEmpty,
    ValidationErrorCode.quantityNotPositive => l10n.errorQuantityNotPositive,
    ValidationErrorCode.expiryIncomplete => l10n.errorExpiryIncomplete,
    ValidationErrorCode.expiryInvalid => l10n.errorExpiryInvalid,
  };
}

extension ExpiryUrgencyL10n on ExpiryUrgency {
  String label(AppLocalizations l10n) => switch (this) {
    ExpiryUrgency.critical => l10n.urgencyExpired,
    ExpiryUrgency.high => l10n.urgencySoon,
    ExpiryUrgency.normal => l10n.urgencyOk,
  };
}
