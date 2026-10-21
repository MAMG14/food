import 'package:flutter/material.dart';
import 'package:food/domain/urgency.dart';

/// Brand seed (Alacena Bunker) for in-app chrome.
const foodSeedColor = Color(0xFF2E7D4F);

/// Splash / onboarding canvas from Figma (cream).
const splashCanvasColor = Color(0xFFF7F3EE);

/// Central Material 3 theme for Alacena Bunker (spec 004).
ThemeData buildFoodTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: foodSeedColor,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
  );
}

Color urgencyForeground(ColorScheme scheme, ExpiryUrgency urgency) {
  return switch (urgency) {
    ExpiryUrgency.critical => scheme.error,
    ExpiryUrgency.high => const Color(0xFFB45309),
    ExpiryUrgency.normal => scheme.primary,
  };
}

Color urgencyBackground(ColorScheme scheme, ExpiryUrgency urgency) {
  return switch (urgency) {
    ExpiryUrgency.critical => scheme.errorContainer,
    ExpiryUrgency.high => const Color(0xFFFFE8CC),
    ExpiryUrgency.normal => scheme.primaryContainer,
  };
}
