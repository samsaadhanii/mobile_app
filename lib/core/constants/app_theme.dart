import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Brand colors ───────────────────────────────────────────────────────────

abstract final class AppColors {
  /// The one seed every colour of the theme is derived from.
  static const seed = Color(0xFF4DB6AC); // teal 300

  // Still read by the version 1 style tool screens.
  static const primary = Color(0xFF80CBC4); // teal 200
  static const secondary = Color(0xFF4DB6AC); // teal 300
  static const scaffoldBg = Color(0xFFF5F5F5);

  // The gradient carries white text and icons, so both ends are dark enough
  // for 4.5 to 1 (teal 700 and teal 800).
  static const gradientStart = Color(0xFF00796B);
  static const gradientEnd = Color(0xFF00695C);
}

// ── Theme ──────────────────────────────────────────────────────────────────

abstract final class AppTheme {
  /// Teal gradient, left to right, for white text.
  static LinearGradient get tealGradient => const LinearGradient(
        colors: [AppColors.gradientStart, AppColors.gradientEnd],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  /// Everything is derived from [AppColors.seed] by Material 3, so no colour
  /// pair is picked by hand. The top bar is the surface colour with the
  /// scheme's own text colour on it; the status-bar icons follow its
  /// brightness.
  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );
    const radius = BorderRadius.all(Radius.circular(12));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurface),
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
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

// ── GradientAppBar ─────────────────────────────────────────────────────────

/// An [AppBar] replacement with the light teal gradient background.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions,
  });

  final String title;
  final bool showBack;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: AppTheme.tealGradient),
      ),
      automaticallyImplyLeading: false,
      leading: showBack ? _BackButton() : null,
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      actions: actions,
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.pop(context),
        child: CircleAvatar(
          backgroundColor: Colors.white.withAlpha(60),
          radius: 16,
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ── GradientButton ─────────────────────────────────────────────────────────

/// A full-width button with the teal gradient background.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDisabled ? null : AppTheme.tealGradient,
          color: isDisabled ? Colors.grey.shade300 : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            splashColor: Colors.white24,
            highlightColor: Colors.white10,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isDisabled ? Colors.grey.shade500 : Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isDisabled ? Colors.grey.shade500 : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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
