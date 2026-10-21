// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Alacena Bunker';

  @override
  String get tabActive => 'Active';

  @override
  String get tabExpired => 'Expired';

  @override
  String get sortByName => 'Sort by name';

  @override
  String get sortByExpiry => 'Sort by expiry';

  @override
  String get emptyActive => 'No active items yet. Add food with the + button.';

  @override
  String get emptyExpired => 'No expired items.';

  @override
  String get addItem => 'Add item';

  @override
  String get editItem => 'Edit item';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldQuantity => 'Quantity';

  @override
  String get fieldUnit => 'Unit';

  @override
  String get fieldCategory => 'Category';

  @override
  String get fieldNotes => 'Notes';

  @override
  String get fieldLocation => 'Location';

  @override
  String get fieldExpiry => 'Expiry';

  @override
  String get precisionDay => 'Exact day';

  @override
  String get precisionMonth => 'Month only';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmDeleteTitle => 'Delete item?';

  @override
  String get confirmDeleteMessage =>
      'This item will be removed from your inventory.';

  @override
  String get errorNameEmpty => 'Enter a name.';

  @override
  String get errorQuantityNotPositive => 'Quantity must be greater than zero.';

  @override
  String get errorExpiryIncomplete => 'Enter an expiry date.';

  @override
  String get errorExpiryInvalid => 'Expiry date is not valid.';

  @override
  String get unitPz => 'pcs';

  @override
  String get unitKg => 'kg';

  @override
  String get unitG => 'g';

  @override
  String get unitL => 'L';

  @override
  String get unitMl => 'ml';

  @override
  String get categoryDairy => 'Dairy';

  @override
  String get categoryMeat => 'Meat';

  @override
  String get categoryVegetables => 'Vegetables';

  @override
  String get categoryPantry => 'Pantry';

  @override
  String get categoryOther => 'Other';

  @override
  String get locationFridge => 'Fridge';

  @override
  String get locationPantry => 'Pantry';

  @override
  String get locationOther => 'Other';

  @override
  String get pickDate => 'Pick date';

  @override
  String get pickMonth => 'Pick month';

  @override
  String get sectionIdentity => 'Item';

  @override
  String get sectionExpiry => 'Expiry';

  @override
  String get sectionQuantity => 'Quantity';

  @override
  String get sectionDetails => 'Details';

  @override
  String get urgencyExpired => 'Expired';

  @override
  String get urgencySoon => 'Soon';

  @override
  String get urgencyOk => 'OK';

  @override
  String get emptyActiveHint => 'Tap + to add the first one.';

  @override
  String get splashTagline => 'Your food bunker for any situation';

  @override
  String get reminderChannelName => 'Expiry reminders';

  @override
  String get reminderChannelDescription => 'Alerts before your food expires';

  @override
  String get reminderWhenToday => 'today';

  @override
  String get reminderWhenTomorrow => 'tomorrow';

  @override
  String reminderWhenOn(String date) {
    return 'on $date';
  }

  @override
  String reminderWhenInMonth(String month) {
    return 'in $month';
  }

  @override
  String reminderItemExpires(String name, String when) {
    return '$name expires $when';
  }

  @override
  String reminderGroupTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items expiring soon',
      one: '1 item expiring soon',
    );
    return '$_temp0';
  }

  @override
  String get reminderSettingsTitle => 'Reminders';

  @override
  String get reminderEnabled => 'Expiry reminders';

  @override
  String get reminderEnabledHint => 'Get notified before your food expires';

  @override
  String get reminderGeneralLead => 'Notify me';

  @override
  String get reminderNotifyAt => 'Reminder time';

  @override
  String get reminderByCategory => 'By category';

  @override
  String get reminderByCategoryHint =>
      'Change how early each category notifies you, or turn it off.';

  @override
  String get reminderLeadSameDay => 'On the expiry day';

  @override
  String reminderLeadDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String reminderRuleGeneral(String lead) {
    return 'Same as general ($lead)';
  }

  @override
  String get reminderRuleOff => 'No reminder';

  @override
  String get reminderPermissionDenied =>
      'Notifications are turned off for Alacena Bunker, so reminders won\'t arrive.';

  @override
  String get reminderOpenSettings => 'Turn on in settings';
}
