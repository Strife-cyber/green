import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Central theme for the app, derived from the [AppColors] brand palette.
///
/// Both [light] and [dark] seed Material's tonal palette with the same brand
/// green, then override the fixed brand swatches (cream canvas, leaf green,
/// warm orange) so every Material widget resolves to one consistent family.
/// Brand typeface. Quicksand's soft, rounded letterforms echo the logo's warm
/// organic cream feel — bundled as static weights in `assets/fonts` (SIL OFL).
const String _fontFamily = 'Quicksand';

abstract final class AppTheme {
  /// Brand-light theme. The cream canvas matches the logo background exactly,
  /// so `assets/logo.png` can be rendered as-is and blend in seamlessly.
  static ThemeData get light => _build(Brightness.light);

  /// Dark theme — deep green-tinted surfaces, same green/orange accents.
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    // Tonally-seeded scheme, then pinned to the exact logo swatches so the
    // seeded tones can never drift the brand off-colour.
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.green,
      onPrimary: Colors.white,
      secondary: AppColors.orange,
      onSecondary: Colors.white,
      tertiary: AppColors.tanDark,
      surface: isLight ? AppColors.background : const Color(0xFF14170F),
      onSurface: isLight ? AppColors.ink : const Color(0xFFEFE7DA),
      surfaceContainerLowest:
          isLight ? const Color(0xFFF6EAD6) : const Color(0xFF0F120D),
      surfaceContainerLow:
          isLight ? const Color(0xFFF0E2CC) : const Color(0xFF1A1E16),
      surfaceContainer:
          isLight ? const Color(0xFFECDBC1) : const Color(0xFF20251B),
      surfaceContainerHigh:
          isLight ? const Color(0xFFE6D3B4) : const Color(0xFF2A3025),
      surfaceContainerHighest:
          isLight ? const Color(0xFFE0CCAA) : const Color(0xFF353C2F),
      surfaceTint: AppColors.green,
      outline: AppColors.tan,
      outlineVariant: isLight ? const Color(0xFFDCC9A8) : const Color(0xFF4A3E2C),
      error: isLight ? const Color(0xFFB3261E) : const Color(0xFFF2B8B5),
    );

    final base = ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: _fontFamily,
    );

    final ink = scheme.onSurface;

    return base.copyWith(
      // App bars melt into the cream canvas — no hard colour band.
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      // Cards lift off the cream with a lighter surface + soft shadow.
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 1,
        shadowColor: AppColors.tanDark.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.greenDark,
          side: const BorderSide(color: AppColors.tan),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.greenDark),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        hintStyle: TextStyle(color: AppColors.tanDark),
        prefixIconColor: AppColors.tanDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.tan),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.tan),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: AppColors.greenContainer,
        labelStyle: TextStyle(color: ink, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? AppColors.ink : scheme.surfaceContainerHigh,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      // Typography inherits Material's ramp but is tinted with brand ink and
      // a green headline accent.
      textTheme: base.textTheme
          .apply(bodyColor: ink, displayColor: ink)
          .copyWith(
            headlineMedium: TextStyle(
              color: AppColors.greenDark,
              fontWeight: FontWeight.w700,
            ),
            headlineSmall: TextStyle(
              color: AppColors.greenDark,
              fontWeight: FontWeight.w700,
            ),
          ),
    );
  }
}
