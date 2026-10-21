import 'package:flutter/material.dart';
import 'package:food/l10n/app_localizations.dart';
import 'package:food/ui/splash/food_mark.dart';
import 'package:food/ui/theme/food_theme.dart';

/// First-run welcome screen (spec 004).
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: foodSeedColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const FoodMark(size: 120),
              const SizedBox(height: 32),
              Text(
                l10n.onboardingWelcome,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onFinished,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: foodSeedColor,
                    minimumSize: const Size.fromHeight(53),
                  ),
                  child: Text(l10n.onboardingStart),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.onboardingTagline,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
