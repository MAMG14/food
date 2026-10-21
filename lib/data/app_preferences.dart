import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight UI prefs (spec 004). Not reminder settings.
class AppPreferences {
  AppPreferences({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const onboardingCompletedKey = 'onboarding_completed';

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _prefs;

  Future<SharedPreferences> _instance() async {
    return _prefs ??= _prefsOverride ?? await SharedPreferences.getInstance();
  }

  Future<bool> isOnboardingCompleted() async {
    final prefs = await _instance();
    return prefs.getBool(onboardingCompletedKey) ?? false;
  }

  Future<void> markOnboardingCompleted() async {
    final prefs = await _instance();
    await prefs.setBool(onboardingCompletedKey, true);
  }

  /// Whether to show first-run onboarding.
  ///
  /// Returns false (and persists completed) when the flag is already set, when
  /// [itemCount] > 0, or when [databaseFileExisted] (upgrade from 001–003).
  Future<bool> shouldShowOnboarding({
    required bool databaseFileExisted,
    required int itemCount,
  }) async {
    if (await isOnboardingCompleted()) return false;
    if (itemCount > 0 || databaseFileExisted) {
      await markOnboardingCompleted();
      return false;
    }
    return true;
  }
}
