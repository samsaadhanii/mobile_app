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
  /// pair is picked by hand. The top bar is the scheme's teal (`primary`) with
  /// its own text colour (`onPrimary`) on it, in light and in dark; the
  /// status bar takes the bar's colour and its icons follow the bar's
  /// brightness.
  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );
    const radius = BorderRadius.all(Radius.circular(12));
    final darkBar =
        ThemeData.estimateBrightnessForColor(scheme.primary) == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        titleTextStyle: TextStyle(
          color: scheme.onPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: scheme.primary,
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
