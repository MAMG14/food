import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Alacena Bunker'**
  String get appTitle;

  /// No description provided for @splashBrandName.
  ///
  /// In en, this message translates to:
  /// **'ALACENA BUNKER'**
  String get splashBrandName;

  /// No description provided for @tabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get tabActive;

  /// No description provided for @tabExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get tabExpired;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Sort by name'**
  String get sortByName;

  /// No description provided for @sortByExpiry.
  ///
  /// In en, this message translates to:
  /// **'Sort by expiry'**
  String get sortByExpiry;

  /// No description provided for @emptyActive.
  ///
  /// In en, this message translates to:
  /// **'No active items yet. Add food with the + button.'**
  String get emptyActive;

  /// No description provided for @emptyExpired.
  ///
  /// In en, this message translates to:
  /// **'No expired items.'**
  String get emptyExpired;

  /// No description provided for @emptySoon.
  ///
  /// In en, this message translates to:
  /// **'Nothing expiring in the next few days.'**
  String get emptySoon;

  /// No description provided for @filterOptimal.
  ///
  /// In en, this message translates to:
  /// **'Optimal'**
  String get filterOptimal;

  /// No description provided for @filterSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get filterSoon;

  /// No description provided for @filterExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get filterExpired;

  /// No description provided for @productsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} products'**
  String productsCount(int count);

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Alacena Bunker'**
  String get onboardingWelcome;

  /// No description provided for @onboardingTagline.
  ///
  /// In en, this message translates to:
  /// **'Your food bunker for any situation'**
  String get onboardingTagline;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @navAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get navAdd;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItem;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get fieldQuantity;

  /// No description provided for @fieldUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get fieldUnit;

  /// No description provided for @fieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldCategory;

  /// No description provided for @fieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get fieldNotes;

  /// No description provided for @fieldLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get fieldLocation;

  /// No description provided for @fieldExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get fieldExpiry;

  /// No description provided for @precisionDay.
  ///
  /// In en, this message translates to:
  /// **'Day / Month / Year'**
  String get precisionDay;

  /// No description provided for @precisionMonth.
  ///
  /// In en, this message translates to:
  /// **'Month / Year'**
  String get precisionMonth;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete item?'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This item will be removed from your inventory.'**
  String get confirmDeleteMessage;

  /// No description provided for @errorNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get errorNameEmpty;

  /// No description provided for @errorQuantityNotPositive.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be greater than zero.'**
  String get errorQuantityNotPositive;

  /// No description provided for @errorExpiryIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Enter an expiry date.'**
  String get errorExpiryIncomplete;

  /// No description provided for @errorExpiryInvalid.
  ///
  /// In en, this message translates to:
  /// **'Expiry date is not valid.'**
  String get errorExpiryInvalid;

  /// No description provided for @unitPz.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get unitPz;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitG.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unitG;

  /// No description provided for @unitL.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get unitL;

  /// No description provided for @unitMl.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get unitMl;

  /// No description provided for @categoryDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get categoryDairy;

  /// No description provided for @categoryMeat.
  ///
  /// In en, this message translates to:
  /// **'Meat'**
  String get categoryMeat;

  /// No description provided for @categoryVegetables.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get categoryVegetables;

  /// No description provided for @categoryPantry.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get categoryPantry;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @locationFridge.
  ///
  /// In en, this message translates to:
  /// **'Fridge'**
  String get locationFridge;

  /// No description provided for @locationPantry.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get locationPantry;

  /// No description provided for @locationOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get locationOther;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get pickDate;

  /// No description provided for @pickMonth.
  ///
  /// In en, this message translates to:
  /// **'Pick month'**
  String get pickMonth;

  /// No description provided for @sectionIdentity.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get sectionIdentity;

  /// No description provided for @sectionExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get sectionExpiry;

  /// No description provided for @sectionQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get sectionQuantity;

  /// No description provided for @sectionDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get sectionDetails;

  /// No description provided for @urgencyExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get urgencyExpired;

  /// No description provided for @urgencySoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get urgencySoon;

  /// No description provided for @urgencyOk.
  ///
  /// In en, this message translates to:
  /// **'Optimal'**
  String get urgencyOk;

  /// No description provided for @emptyActiveHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add the first one.'**
  String get emptyActiveHint;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Your food bunker for any situation'**
  String get splashTagline;

  /// No description provided for @reminderChannelName.
  ///
  /// In en, this message translates to:
  /// **'Expiry reminders'**
  String get reminderChannelName;

  /// No description provided for @reminderChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Alerts before your food expires'**
  String get reminderChannelDescription;

  /// No description provided for @reminderWhenToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get reminderWhenToday;

  /// No description provided for @reminderWhenTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get reminderWhenTomorrow;

  /// No description provided for @reminderWhenOn.
  ///
  /// In en, this message translates to:
  /// **'on {date}'**
  String reminderWhenOn(String date);

  /// No description provided for @reminderWhenInMonth.
  ///
  /// In en, this message translates to:
  /// **'in {month}'**
  String reminderWhenInMonth(String month);

  /// No description provided for @reminderItemExpires.
  ///
  /// In en, this message translates to:
  /// **'{name} expires {when}'**
  String reminderItemExpires(String name, String when);

  /// No description provided for @reminderGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item expiring soon} other{{count} items expiring soon}}'**
  String reminderGroupTitle(int count);

  /// No description provided for @reminderSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminderSettingsTitle;

  /// No description provided for @reminderEnabled.
  ///
  /// In en, this message translates to:
  /// **'Expiry reminders'**
  String get reminderEnabled;

  /// No description provided for @reminderEnabledHint.
  ///
  /// In en, this message translates to:
  /// **'Get notified before your food expires'**
  String get reminderEnabledHint;

  /// No description provided for @reminderGeneralLead.
  ///
  /// In en, this message translates to:
  /// **'Notify me'**
  String get reminderGeneralLead;

  /// No description provided for @reminderNotifyAt.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderNotifyAt;

  /// No description provided for @reminderByCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get reminderByCategory;

  /// No description provided for @reminderByCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Change how early each category notifies you, or turn it off.'**
  String get reminderByCategoryHint;

  /// No description provided for @reminderLeadSameDay.
  ///
  /// In en, this message translates to:
  /// **'On the expiry day'**
  String get reminderLeadSameDay;

  /// No description provided for @reminderLeadDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day before} other{{days} days before}}'**
  String reminderLeadDays(int days);

  /// No description provided for @reminderRuleGeneral.
  ///
  /// In en, this message translates to:
  /// **'Same as general ({lead})'**
  String reminderRuleGeneral(String lead);

  /// No description provided for @reminderRuleOff.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get reminderRuleOff;

  /// No description provided for @reminderPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off for Alacena Bunker, so reminders won\'t arrive.'**
  String get reminderPermissionDenied;

  /// No description provided for @reminderOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Turn on in settings'**
  String get reminderOpenSettings;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan product'**
  String get scanTitle;

  /// No description provided for @scanRegisterManual.
  ///
  /// In en, this message translates to:
  /// **'Register manually'**
  String get scanRegisterManual;

  /// No description provided for @scanLookingUp.
  ///
  /// In en, this message translates to:
  /// **'Looking up product…'**
  String get scanLookingUp;

  /// No description provided for @scanCameraDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera access needed'**
  String get scanCameraDeniedTitle;

  /// No description provided for @scanCameraDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'Enable camera permission or register the product manually.'**
  String get scanCameraDeniedBody;

  /// No description provided for @scanNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that product. You can register it manually.'**
  String get scanNotFound;

  /// No description provided for @scanNetworkError.
  ///
  /// In en, this message translates to:
  /// **'No internet or the lookup failed. You can register it manually.'**
  String get scanNetworkError;

  /// No description provided for @scanConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm product'**
  String get scanConfirmTitle;

  /// No description provided for @scanSave.
  ///
  /// In en, this message translates to:
  /// **'Save to inventory'**
  String get scanSave;

  /// No description provided for @productImageOpen.
  ///
  /// In en, this message translates to:
  /// **'View photo'**
  String get productImageOpen;

  /// No description provided for @productImageAdd.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get productImageAdd;

  /// No description provided for @productImageCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get productImageCamera;

  /// No description provided for @productImageGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get productImageGallery;

  /// No description provided for @productImageReplace.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get productImageReplace;

  /// No description provided for @productImageRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get productImageRemove;

  /// No description provided for @productImagePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Photo permission denied. You can still save the item without an image.'**
  String get productImagePermissionDenied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
