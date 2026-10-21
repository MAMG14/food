import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food/ui/theme/food_theme.dart';
import 'package:lottie/lottie.dart';

/// Asset path for the Alacena Bunker splash animation (spec 004).
const kSplashLottieAsset = 'assets/lottie/alacena_bunker_splash.json';

/// Natural Lottie length (~1.5 s at 30 fps).
const kSplashDuration = Duration(milliseconds: 1500);

/// Hard cap if the animation never reports completion.
const kSplashFallbackMax = Duration(seconds: 2);

/// Brand splash: always the Lottie, then fade into [child].
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

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  bool _showSplash = true;
  bool _completed = false;
  AnimationController? _lottieController;

  @override
  void initState() {
    super.initState();
    if (widget.duration == Duration.zero) {
      _showSplash = false;
      return;
    }
    _lottieController = AnimationController(vsync: this);
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
              onLoaded: _onLottieLoaded,
              onFailed: _finish,
            )
          : KeyedSubtree(key: const ValueKey('home'), child: widget.child),
    );
  }
}

class SplashView extends StatelessWidget {
  const SplashView({
    super.key,
    this.controller,
    this.onLoaded,
    this.onFailed,
  });

  final AnimationController? controller;
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
            child: controller == null
                ? const SizedBox.shrink()
                : Lottie.asset(
                    kSplashLottieAsset,
                    controller: controller,
                    width: 240,
                    height: 240,
                    fit: BoxFit.contain,
                    onLoaded: onLoaded,
                    errorBuilder: (context, error, stackTrace) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        onFailed?.call();
                      });
                      return const SizedBox.shrink();
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
