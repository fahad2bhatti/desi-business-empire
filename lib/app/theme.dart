import 'package:flutter/material.dart';

/// Direction: dark tycoon. A night bazaar of glowing shop signs: deep navy
/// ground, raised panels, gold money, green income, and one signal colour
/// per category so each kind of business is recognisable at a glance.
abstract final class AppSpacing {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
}

abstract final class AppRadius {
  static const control = 12.0;
  static const card = 18.0;
  static const tile = 14.0;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120);
  static const medium = Duration(milliseconds: 240);
  static const counter = Duration(milliseconds: 900);
  static const curve = Curves.easeOutCubic;
}

/// Theme colours. Read with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.inkMuted,
    required this.gold,
    required this.onGold,
    required this.income,
    required this.onIncome,
    required this.danger,
    required this.street,
    required this.shops,
    required this.companies,
    required this.property,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color ink;
  final Color inkMuted;

  /// Money: the cash counter, prices, upgrade buttons.
  final Color gold;
  final Color onGold;

  /// Earnings per second and the buy button.
  final Color income;
  final Color onIncome;

  /// Selling and errors.
  final Color danger;

  // One signal colour per category.
  final Color street;
  final Color shops;
  final Color companies;
  final Color property;

  Color get hairline => ink.withValues(alpha: 0.08);

  Color category(String id) => switch (id) {
    'street' => street,
    'shops' => shops,
    'companies' => companies,
    _ => property,
  };

  static const night = AppPalette(
    background: Color(0xFF0D1117),
    surface: Color(0xFF161B24),
    surfaceRaised: Color(0xFF1F2632),
    ink: Color(0xFFF3F5F8),
    inkMuted: Color(0xFF9AA4B2),
    gold: Color(0xFFF5C451),
    onGold: Color(0xFF2B1F00),
    income: Color(0xFF4CD787),
    onIncome: Color(0xFF00210F),
    danger: Color(0xFFFF7A70),
    street: Color(0xFFFF9447),
    shops: Color(0xFF5AA9FF),
    companies: Color(0xFFB794FF),
    property: Color(0xFF3ED6C4),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) => this;
}

extension ThemeX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

/// Tabular figures so numbers do not jump as they change every second.
extension NumberStyle on TextStyle? {
  TextStyle get numbers => (this ?? const TextStyle()).copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

ThemeData buildAppTheme() {
  const p = AppPalette.night;
  final scheme = ColorScheme.fromSeed(
    seedColor: p.income,
    brightness: Brightness.dark,
    primary: p.income,
    onPrimary: p.onIncome,
    secondary: p.gold,
    onSecondary: p.onGold,
    secondaryContainer: p.surfaceRaised,
    onSecondaryContainer: p.ink,
    surface: p.surface,
    onSurface: p.ink,
    onSurfaceVariant: p.inkMuted,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surfaceRaised,
    surfaceContainerLow: p.background,
    outline: p.inkMuted,
    outlineVariant: p.hairline,
    error: p.danger,
  );

  final base = Typography.material2021(platform: TargetPlatform.android).white;
  final text = base
      .copyWith(
        displaySmall: base.displaySmall?.copyWith(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: base.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: base.titleSmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.bodyLarge?.copyWith(fontSize: 16),
        bodyMedium: base.bodyMedium?.copyWith(fontSize: 14),
        bodySmall: base.bodySmall?.copyWith(fontSize: 12),
        labelLarge: base.labelLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        labelSmall: base.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      )
      .apply(bodyColor: p.ink, displayColor: p.ink);

  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.control),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    textTheme: text,
    scaffoldBackgroundColor: p.background,
    extensions: const [p],
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.hairline, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: controlShape,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: controlShape,
        foregroundColor: p.ink,
        side: BorderSide(color: p.ink.withValues(alpha: 0.2)),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: p.gold,
        textStyle: text.labelLarge,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.gold,
      linearTrackColor: p.surfaceRaised,
      linearMinHeight: 6,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.surfaceRaised,
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(text.labelSmall),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? p.gold : p.inkMuted,
        ),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: p.ink,
      unselectedLabelColor: p.inkMuted,
      indicatorColor: p.gold,
      dividerColor: p.hairline,
      labelStyle: text.titleSmall,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.surfaceRaised,
      contentTextStyle: text.bodyMedium,
    ),
    dialogTheme: DialogThemeData(backgroundColor: p.surfaceRaised),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.surface),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surfaceRaised,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
