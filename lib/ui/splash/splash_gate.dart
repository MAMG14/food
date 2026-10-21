import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/ui/theme/food_theme.dart';
import 'package:lottie/lottie.dart';

/// Asset path for the Alacena Bunker splash animation (spec 004).
const kSplashLottieAsset = 'assets/lottie/alacena_bunker_splash.json';

/// Natural Lottie length (~1.5 s at 30 fps).
const kSplashDuration = Duration(milliseconds: 1500);

/// Hard cap if load/play never completes.
const kSplashFallbackMax = Duration(seconds: 3);

/// Brand splash: Lottie + «ALACENA BUNKER» (Figma), then fade into [child].
class SplashGate extends StatefulWidget {
  const SplashGate({
    super.key,
    required this.child,
    this.duration = kSplashDuration,
  });

  final Widget child;

  /// [Duration.zero] skips the splash (tests).
  final Duration duration;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _showSplash = true;
  bool _completed = false;
  LottieComposition? _composition;

  @override
  void initState() {
    super.initState();
    if (widget.duration == Duration.zero) {
      _showSplash = false;
      return;
    }
    _load();
    Future<void>.delayed(kSplashFallbackMax, _finish);
  }

  Future<void> _load() async {
    try {
      final composition = await AssetLottie(kSplashLottieAsset).load();
      if (!mounted || _completed) return;
      setState(() => _composition = composition);
      await Future<void>.delayed(composition.duration);
      _finish();
    } catch (e, st) {
      debugPrint('Splash Lottie failed: $e\n$st');
      _finish();
    }
  }

  void _finish() {
    if (_completed || !mounted) return;
    _completed = true;
    setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _showSplash
          ? SplashView(
              key: const ValueKey('splash'),
              composition: _composition,
            )
          : KeyedSubtree(key: const ValueKey('home'), child: widget.child),
    );
  }
}

class SplashView extends StatelessWidget {
  const SplashView({super.key, this.composition});

  final LottieComposition? composition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const bg = splashCanvasColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: bg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (composition == null)
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(color: foodSeedColor),
                  )
                else
                  Lottie(
                    composition: composition,
                    width: 160,
                    height: 200,
                    fit: BoxFit.contain,
                    repeat: false,
                  ),
                const SizedBox(height: 16),
                Text(
                  l10n.splashBrandName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
