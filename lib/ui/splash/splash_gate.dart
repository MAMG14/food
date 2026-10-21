import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food/ui/splash/food_mark.dart';
import 'package:food/ui/theme/food_theme.dart';
import 'package:lottie/lottie.dart';

/// Asset path for the Alacena Bunker splash animation (spec 004).
const kSplashLottieAsset = 'assets/lottie/alacena_bunker_splash.json';

/// Natural Lottie length (~1.5 s at 30 fps).
const kSplashDuration = Duration(milliseconds: 1500);

/// Hard cap if the animation never reports completion.
const kSplashFallbackMax = Duration(seconds: 2);

/// Native-matching splash (Lottie), then fade into [child].
class SplashGate extends StatefulWidget {
  const SplashGate({
    super.key,
    required this.child,
    this.duration = kSplashDuration,
  });

  final Widget child;

  /// [Duration.zero] skips the splash (tests). Otherwise used as a minimum
  /// wait before revealing [child] when Lottie is unavailable.
  final Duration duration;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  bool _showSplash = true;
  bool _completed = false;
  AnimationController? _lottieController;
  var _useFallback = false;

  @override
  void initState() {
    super.initState();
    if (widget.duration == Duration.zero) {
      _showSplash = false;
      return;
    }
    _lottieController = AnimationController(vsync: this);
    _armFallbackTimer();
  }

  void _armFallbackTimer() {
    Future<void>.delayed(kSplashFallbackMax, () {
      if (!mounted || _completed) return;
      _finish();
    });
  }

  void _finish() {
    if (_completed || !mounted) return;
    _completed = true;
    _lottieController?.stop();
    setState(() => _showSplash = false);
  }

  void _onLottieLoaded(LottieComposition composition) {
    final controller = _lottieController;
    if (controller == null) return;
    controller
      ..duration = composition.duration
      ..forward().whenComplete(_finish);
  }

  void _onLottieFailed() {
    if (!mounted) return;
    setState(() => _useFallback = true);
    Future<void>.delayed(widget.duration, () {
      if (!mounted || _completed) return;
      _finish();
    });
  }

  @override
  void dispose() {
    _lottieController?.dispose();
    super.dispose();
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
              controller: _lottieController,
              useFallback: _useFallback,
              onLoaded: _onLottieLoaded,
              onFailed: _onLottieFailed,
            )
          : KeyedSubtree(key: const ValueKey('home'), child: widget.child),
    );
  }
}

class SplashView extends StatelessWidget {
  const SplashView({
    super.key,
    this.controller,
    this.useFallback = false,
    this.onLoaded,
    this.onFailed,
  });

  final AnimationController? controller;
  final bool useFallback;
  final void Function(LottieComposition composition)? onLoaded;
  final VoidCallback? onFailed;

  @override
  Widget build(BuildContext context) {
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
            child: useFallback || controller == null
                ? const FoodMark(size: 160)
                : Lottie.asset(
                    kSplashLottieAsset,
                    controller: controller,
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,
                    onLoaded: onLoaded,
                    errorBuilder: (context, error, stackTrace) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        onFailed?.call();
                      });
                      return const FoodMark(size: 160);
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
