import 'package:flutter_test/flutter_test.dart';
import 'package:food/data/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = AppPreferences(prefs: await SharedPreferences.getInstance());
  });

  test('onboarding defaults to not completed', () async {
    expect(await prefs.isOnboardingCompleted(), isFalse);
  });

  test('markOnboardingCompleted persists', () async {
    await prefs.markOnboardingCompleted();
    expect(await prefs.isOnboardingCompleted(), isTrue);
  });

  test('clean install empty inventory shows onboarding', () async {
    expect(
      await prefs.shouldShowOnboarding(
        databaseFileExisted: false,
        itemCount: 0,
      ),
      isTrue,
    );
    expect(await prefs.isOnboardingCompleted(), isFalse);
  });

  test('items present skips onboarding and marks completed', () async {
    expect(
      await prefs.shouldShowOnboarding(
        databaseFileExisted: false,
        itemCount: 3,
      ),
      isFalse,
    );
    expect(await prefs.isOnboardingCompleted(), isTrue);
  });

  test('prior DB with zero items skips onboarding', () async {
    expect(
      await prefs.shouldShowOnboarding(
        databaseFileExisted: true,
        itemCount: 0,
      ),
      isFalse,
    );
    expect(await prefs.isOnboardingCompleted(), isTrue);
  });

  test('already completed never shows again', () async {
    await prefs.markOnboardingCompleted();
    expect(
      await prefs.shouldShowOnboarding(
        databaseFileExisted: false,
        itemCount: 0,
      ),
      isFalse,
    );
  });
}
