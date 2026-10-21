import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:food/data/app_preferences.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/domain/home_filter.dart';
import 'package:food/l10n/app_locale.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/notifications/reminder_scheduler.dart';
import 'package:food/ui/onboarding/onboarding_page.dart';
import 'package:food/ui/shell/home_shell.dart';
import 'package:food/ui/splash/splash_gate.dart';
import 'package:food/ui/theme/food_theme.dart';

class FoodApp extends StatefulWidget {
  const FoodApp({
    super.key,
    required this.repository,
    required this.reminders,
    required this.preferences,
    this.showOnboarding = false,
    this.splashDuration = kSplashDuration,
  });

  final FoodItemRepository repository;
  final ReminderScheduler reminders;
  final AppPreferences preferences;

  /// Resolved in [main] via [AppPreferences.shouldShowOnboarding].
  final bool showOnboarding;

  /// [Duration.zero] skips the branded splash (tests).
  final Duration splashDuration;

  @override
  State<FoodApp> createState() => _FoodAppState();
}

class _FoodAppState extends State<FoodApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  /// Reminder tap → Home filter [HomeFilter.soon].
  final _reminderFilter = ValueNotifier<HomeFilter?>(null);

  late bool _showOnboarding;

  StreamSubscription<void>? _tapSubscription;
  AppLifecycleListener? _lifecycle;

  ReminderScheduler get _reminders => widget.reminders;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
    _tapSubscription = _reminders.gateway.taps.listen((_) => _onReminderTap());
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    unawaited(_startReminders());
  }

  Future<void> _startReminders() async {
    await _reminders.resync();
    await Future<void>.delayed(widget.splashDuration);
    if (!mounted) return;
    final settings = await _reminders.settings.load();
    if (settings.permissionAsked) return;
    await _reminders.gateway.requestPermission();
    await _reminders.settings.save(settings.copyWith(permissionAsked: true));
  }

  Future<void> _onResume() async {
    await _reminders.gateway.refreshTimeZone();
    await _reminders.resync();
  }

  void _onReminderTap() {
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    _reminderFilter.value = HomeFilter.soon;
  }

  Future<void> _finishOnboarding() async {
    await widget.preferences.markOnboardingCompleted();
    if (!mounted) return;
    setState(() => _showOnboarding = false);
  }

  @override
  void dispose() {
    _tapSubscription?.cancel();
    _lifecycle?.dispose();
    _reminderFilter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = HomeShell(
      repository: widget.repository,
      reminders: _reminders,
      reminderFilter: _reminderFilter,
    );

    final afterSplash = _showOnboarding
        ? OnboardingPage(onFinished: () => unawaited(_finishOnboarding()))
        : shell;

    return MaterialApp(
      navigatorKey: _navigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: appLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildFoodTheme(),
      home: widget.splashDuration == Duration.zero
          ? afterSplash
          : SplashGate(duration: widget.splashDuration, child: afterSplash),
    );
  }
}
