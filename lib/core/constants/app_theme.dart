import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Brand colors ───────────────────────────────────────────────────────────

abstract final class AppColors {
  /// The one seed every colour of the theme is derived from.
  static const seed = Color(0xFF4DB6AC); // teal 300
}

// ── Theme ──────────────────────────────────────────────────────────────────

abstract final class AppTheme {
  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  /// Everything is derived from [AppColors.seed] by Material 3, so no colour
  /// pair is picked by hand. The top bar is teal with the scheme's own text
  /// colour on it: `primary` with `onPrimary` in light, and in dark the dark
  /// teal `primaryContainer` with `onPrimaryContainer`, so a dark screen does
  /// not get a light bar across the top. The status bar takes the bar's colour
  /// and its icons follow the bar's brightness.
  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );
    const radius = BorderRadius.all(Radius.circular(12));
    final light = brightness == Brightness.light;
    final barColor = light ? scheme.primary : scheme.primaryContainer;
    final barText = light ? scheme.onPrimary : scheme.onPrimaryContainer;
    final darkBar =
        ThemeData.estimateBrightnessForColor(barColor) == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: barColor,
        foregroundColor: barText,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: barText),
        titleTextStyle: TextStyle(
          color: barText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: barColor,
          // Android: the icons' colour. iOS: the brightness of what is
          // behind them.
          statusBarIconBrightness: darkBar ? Brightness.light : Brightness.dark,
          statusBarBrightness: darkBar ? Brightness.dark : Brightness.light,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
