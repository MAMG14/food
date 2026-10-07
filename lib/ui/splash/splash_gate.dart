import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/ui/splash/food_mark.dart';
import 'package:food/ui/theme/food_theme.dart';

/// Default time the branded splash stays after the first Flutter frame.
const kSplashDuration = Duration(milliseconds: 900);

/// Native-matching splash, then fade into [child] (the inventory).
class SplashGate extends StatefulWidget {
  const SplashGate({
    super.key,
    required this.child,
    this.duration = kSplashDuration,
  });

  final Widget child;
  final Duration duration;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _completeAfterDelay();
  }

  Future<void> _completeAfterDelay() async {
    await Future<void>.delayed(widget.duration);
    if (!mounted) return;
    setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _showSplash
          ? const SplashView(key: ValueKey('splash'))
          : KeyedSubtree(key: const ValueKey('home'), child: widget.child),
    );
  }
}

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const onSplash = Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: foodSeedColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: foodSeedColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FoodMark(),
                  const SizedBox(height: 24),
                  Text(
                    l10n.appTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: onSplash,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.splashTagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: onSplash.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
