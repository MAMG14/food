import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:food/data/food_item_repository.dart';
import 'package:food/l10n/app_locale.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/notifications/reminder_scheduler.dart';
import 'package:food/ui/home/inventory_page.dart';
import 'package:food/ui/splash/splash_gate.dart';
import 'package:food/ui/theme/food_theme.dart';

class FoodApp extends StatefulWidget {
  const FoodApp({
    super.key,
    required this.repository,
    required this.reminders,
    this.splashDuration = kSplashDuration,
  });

  final FoodItemRepository repository;
  final ReminderScheduler reminders;

  /// [Duration.zero] skips the branded splash (tests that go straight home).
  final Duration splashDuration;

  @override
  State<FoodApp> createState() => _FoodAppState();
}

class _FoodAppState extends State<FoodApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  /// Bumped when a reminder is tapped; the inventory switches to Active.
  final _showActive = ValueNotifier<int>(0);

  StreamSubscription<void>? _tapSubscription;
  AppLifecycleListener? _lifecycle;

  ReminderScheduler get _reminders => widget.reminders;

  @override
  void initState() {
    super.initState();
    _tapSubscription = _reminders.gateway.taps.listen((_) => _openActive());
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    unawaited(_startReminders());
  }

  Future<void> _startReminders() async {
    await _reminders.resync();
    // Ask once, after the splash, so the dialog doesn't cover the brand.
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

  void _openActive() {
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    _showActive.value++;
  }

  @override
  void dispose() {
    _tapSubscription?.cancel();
    _lifecycle?.dispose();
    _showActive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = InventoryPage(
      repository: widget.repository,
      reminders: _reminders,
      showActive: _showActive,
    );
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
          ? home
          : SplashGate(duration: widget.splashDuration, child: home),
    );
  }
}
