import 'package:flutter/material.dart';

/// Colors from docs/frontend-specification-document.md (proposal).
abstract final class AppColors {
  static const background = Color(0xFFFFF8ED);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFEADFCB);
  static const teal = Color(0xFF155E63);
  static const tealDark = Color(0xFF0F474B);
  static const tealLight = Color(0xFFE3F0EF);

  /// Secondary text on a teal background.
  static const onTealMuted = Color(0xFFCFE6E4);
  static const amber = Color(0xFFE6A23C);
  static const amberLight = Color(0xFFFBEBD0);
  static const amberInk = Color(0xFF6E4C14);
  static const text = Color(0xFF202A32);
  static const muted = Color(0xFF5B6670);
  static const terra = Color(0xFFA8462A);
  static const terraLight = Color(0xFFF7E3DA);
  static const green = Color(0xFF2E6B3A);
  static const track = Color(0xFFEFE6D6);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.teal,
    primary: AppColors.teal,
    onPrimary: Colors.white,
    surface: AppColors.background,
    onSurface: AppColors.text,
    error: AppColors.terra,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  const minSize = Size(48, 48);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minSize,
        shape: shape,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minSize,
        shape: shape,
        foregroundColor: AppColors.teal,
        side: const BorderSide(color: AppColors.teal, width: 1.5),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
  );
}
