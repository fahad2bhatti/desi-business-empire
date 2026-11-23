import 'package:flutter/material.dart';

/// Direction: calm private-banking app, in a dark and a light theme. Light is
/// the default: airy, muted colours, generous spacing, soft round cards.
///
/// The focus rule: every screen has exactly one accent-filled element, the
/// thing the player should do next ([FocusCard] or one `FilledButton`).
/// Everything else stays neutral: tonal buttons, grey icon tiles, colour
/// only in a small category dot. Green is kept for income numbers, red for
/// selling and errors. Nothing else is coloured.
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
  static const control = 14.0;
  static const card = 22.0;
  static const tile = 16.0;
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
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.inkMuted,
    required this.accent,
    required this.onAccent,
    required this.accentInk,
    required this.income,
    required this.danger,
    required this.onDanger,
    required this.street,
    required this.transport,
    required this.shops,
    required this.companies,
    required this.property,
    required this.lifestyle,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color ink;
  final Color inkMuted;

  /// The one focus colour: fills the next-move card and its button.
  final Color accent;
  final Color onAccent;

  /// Accent as text on a surface: links, the selected tab, small labels.
  final Color accentInk;

  /// Earnings only: income per second, rent, rewards.
  final Color income;

  /// Selling and errors.
  final Color danger;
  final Color onDanger;

  // Category dots. Small marks only, never fills.
  final Color street;
  final Color transport;
  final Color shops;
  final Color companies;
  final Color property;
  final Color lifestyle;

  Color get hairline => ink.withValues(alpha: 0.08);

  Color category(String id) => switch (id) {
    'street' => street,
    'transport' => transport,
    'shops' => shops,
    'companies' => companies,
    'lifestyle' => lifestyle,
    _ => property,
  };

  /// Soft background for a category tile: the category colour, very light,
  /// over the screen surface.
  Color tint(String id) => Color.alphaBlend(
    category(id).withValues(alpha: brightness == Brightness.dark ? 0.16 : 0.13),
    surface,
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0E1217),
    surface: Color(0xFF161C23),
    surfaceRaised: Color(0xFF1E2630),
    ink: Color(0xFFEEF2F6),
    inkMuted: Color(0xFF94A0AE),
    accent: Color(0xFF3A6AD9),
    onAccent: Color(0xFFFFFFFF),
    accentInk: Color(0xFF8DB0FF),
    income: Color(0xFF3DC985),
    danger: Color(0xFFF2706A),
    onDanger: Color(0xFF1A0B0A),
    street: Color(0xFFE0915A),
    transport: Color(0xFF5CB8C9),
    shops: Color(0xFF7FA6E8),
    companies: Color(0xFFA792E0),
    property: Color(0xFF6CC4A1),
    lifestyle: Color(0xFFC79A96),
  );

  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF5F6F3),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFE9EEF2),
    ink: Color(0xFF1E2A32),
    inkMuted: Color(0xFF5F6A75),
    accent: Color(0xFF3E6A8A),
    onAccent: Color(0xFFFFFFFF),
    accentInk: Color(0xFF3E6A8A),
    income: Color(0xFF2F7553),
    danger: Color(0xFFB5544C),
    onDanger: Color(0xFFFFFFFF),
    street: Color(0xFFD9A872),
    transport: Color(0xFF7FB0B8),
    shops: Color(0xFF8FA3CE),
    companies: Color(0xFFAB9CC9),
    property: Color(0xFF8DB89F),
    lifestyle: Color(0xFFC9A3A0),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) =>
      other == null || t < 0.5 ? this : other;
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

ThemeData buildAppTheme([AppPalette p = AppPalette.dark]) {
  final isDark = p.brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: p.accent,
    brightness: p.brightness,
    primary: p.accent,
    onPrimary: p.onAccent,
    secondary: p.accentInk,
    onSecondary: p.onAccent,
    secondaryContainer: p.surfaceRaised,
    onSecondaryContainer: p.ink,
    surface: p.surface,
    onSurface: p.ink,
    onSurfaceVariant: p.inkMuted,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surfaceRaised,
    surfaceContainerHighest: p.surfaceRaised,
    surfaceContainerLow: p.background,
    outline: p.inkMuted,
    outlineVariant: p.hairline,
    error: p.danger,
    onError: p.onDanger,
  );

  final typography = Typography.material2021(platform: TargetPlatform.android);
  final base = isDark ? typography.white : typography.black;
  final text = base
      .copyWith(
        displaySmall: base.displaySmall?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.1,
          letterSpacing: -0.5,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: base.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: base.titleSmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.bodyLarge?.copyWith(fontSize: 16),
        bodyMedium: base.bodyMedium?.copyWith(fontSize: 14),
        bodySmall: base.bodySmall?.copyWith(fontSize: 13),
        labelLarge: base.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelSmall: base.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      )
      .apply(bodyColor: p.ink, displayColor: p.ink);

  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.control),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    textTheme: text,
    scaffoldBackgroundColor: p.background,
    extensions: [p],
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
        side: isDark ? BorderSide.none : BorderSide(color: p.hairline),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.hairline, thickness: 1, space: 1),
    // Filled = the focus action. Tonal (FilledButton.tonal) = everything else.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: controlShape,
        textStyle: text.labelLarge,
        disabledBackgroundColor: p.surfaceRaised,
        disabledForegroundColor: p.inkMuted,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: controlShape,
        foregroundColor: p.ink,
        side: BorderSide(color: p.ink.withValues(alpha: 0.18)),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: p.accentInk,
        textStyle: text.labelLarge,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.inkMuted,
      linearTrackColor: p.surfaceRaised,
      linearMinHeight: 4,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelSmall?.copyWith(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? p.accentInk
              : p.inkMuted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 26,
          color: states.contains(WidgetState.selected)
              ? p.accentInk
              : p.inkMuted,
        ),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: p.ink,
      unselectedLabelColor: p.inkMuted,
      indicatorColor: p.accentInk,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: p.hairline,
      labelStyle: text.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: text.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.ink,
      contentTextStyle: text.bodyMedium?.copyWith(color: p.background),
    ),
    dialogTheme: DialogThemeData(backgroundColor: p.surface),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.surface),
    popupMenuTheme: PopupMenuThemeData(color: p.surfaceRaised),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? p.accent : p.surfaceRaised,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? p.onAccent : p.inkMuted,
      ),
    ),
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
