import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food/ui/theme/food_theme.dart';
import 'package:lottie/lottie.dart';

/// Animated mark (cropped).
const kSplashLottieAsset = 'assets/lottie/alacena_bunker_splash.json';

/// Full splash still (logo + wordmark) — matches Android native splash.
const kSplashScreenAsset = 'assets/images/splash_screen.png';

/// Design size of [kSplashScreenAsset] (Figma 412×917 @3x).
const Size kSplashScreenDesignSize = Size(1236, 2751);

/// Icon rect inside [kSplashScreenDesignSize].
const Rect kSplashIconInDesign = Rect.fromLTWH(450, 1045, 336, 531);

const kSplashDuration = Duration(milliseconds: 1500);
const kSplashFallbackMax = Duration(seconds: 3);

/// Brand splash: native-matching still, then Lottie over the icon slot.
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
    // No cross-fade on the splash itself (avoids a second “jump”).
    if (!_showSplash) {
      return KeyedSubtree(key: const ValueKey('home'), child: widget.child);
    }
    return SplashView(
      key: const ValueKey('splash'),
      composition: _composition,
    );
  }
}

class SplashView extends StatelessWidget {
  const SplashView({super.key, this.composition});

  final LottieComposition? composition;

  /// Where the icon sits when [kSplashScreenAsset] is drawn with [BoxFit.cover].
  static Rect iconRectForCover(Size screen) {
    final image = kSplashScreenDesignSize;
    final scale = math.max(screen.width / image.width, screen.height / image.height);
    final fittedW = image.width * scale;
    final fittedH = image.height * scale;
    final dx = (screen.width - fittedW) / 2;
    final dy = (screen.height - fittedH) / 2;
    final r = kSplashIconInDesign;
    return Rect.fromLTWH(
      dx + r.left * scale,
      dy + r.top * scale,
      r.width * scale,
      r.height * scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = splashCanvasColor;
    final screen = MediaQuery.sizeOf(context);
    final iconRect = iconRectForCover(screen);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: bg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Same frame as the Android launch image → seamless handoff.
            Image.asset(
              kSplashScreenAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
            ),
            if (composition != null)
              Positioned(
                left: iconRect.left,
                top: iconRect.top,
                width: iconRect.width,
                height: iconRect.height,
                child: Lottie(
                  composition: composition,
                  fit: BoxFit.contain,
                  repeat: false,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
