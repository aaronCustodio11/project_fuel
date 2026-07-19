import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color brandBlue = Color(0xFF2E6FE0);
  static const Color brandBlueDark = Color(0xFF1B4DB5);
  static const Color navyDeep = Color(0xFF0F2942);
  static const Color navyMid = Color(0xFF1B3A5C);
  static const Color accentBlue = Color(0xFF2E6FE0);
  static const Color dangerRed = Color(0xFFD93025);
  static const Color warningAmber = Color(0xFFF5A623);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color neutralGray900 = Color(0xFF1A1D21);
  static const Color neutralGray500 = Color(0xFF6B7280);
  static const Color neutralGray200 = Color(0xFFE5E7EB);
  static const Color neutralGray50 = Color(0xFFF7F8FA);

  // Entity-specific marker colors for maps
  static const Color truckMoving = Color(0xFF16A34A);
  static const Color stationGas = Color(0xFFFFAB40);
  static const Color stationDepot = Color(0xFF1565C0);

  static ThemeData lightTheme = buildFleetSenseTheme(Brightness.light);
  static ThemeData darkTheme = buildFleetSenseTheme(Brightness.dark);

  static ThemeData buildFleetSenseTheme(Brightness brightness) {
    final scheme = brightness == Brightness.light ? _lightScheme : _darkScheme;
    final statusColors = brightness == Brightness.light
        ? FleetStatusColors.light
        : FleetStatusColors.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLow,
      textTheme: _textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      extensions: [statusColors],
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FleetRadius.md),
          side: BorderSide(color: scheme.outline, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FleetRadius.sm),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: FleetSpacing.lg,
            vertical: FleetSpacing.md,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FleetRadius.sm),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: FleetSpacing.lg,
            vertical: FleetSpacing.md,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FleetRadius.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FleetRadius.sm),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 0,
      ),
    );
  }

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2E6FE0),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD6E4FC),
    onPrimaryContainer: Color(0xFF001B5E),
    secondary: Color(0xFF2E6FE0),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE3ECFC),
    onSecondaryContainer: Color(0xFF163B82),
    tertiary: Color(0xFFF5A623),
    onTertiary: Color(0xFF3A2600),
    tertiaryContainer: Color(0xFFFCEACB),
    onTertiaryContainer: Color(0xFF5C3D00),
    error: Color(0xFFD93025),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFAD9D6),
    onErrorContainer: Color(0xFF7A1610),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1A1D21),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7F8FA),
    surfaceContainer: Color(0xFFF1F2F4),
    surfaceContainerHigh: Color(0xFFE9EBEE),
    surfaceContainerHighest: Color(0xFFE2E4E8),
    onSurfaceVariant: Color(0xFF6B7280),
    outline: Color(0xFFE5E7EB),
    outlineVariant: Color(0xFFEFF0F2),
    inverseSurface: Color(0xFF0F2942),
    onInverseSurface: Color(0xFFF7F8FA),
    inversePrimary: Color(0xFF5DE0FF),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0xFF2E6FE0),
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF5DE0FF),
    onPrimary: Color(0xFF003F55),
    primaryContainer: Color(0xFF005577),
    onPrimaryContainer: Color(0xFFB5F5FF),
    secondary: Color(0xFF7AA6F2),
    onSecondary: Color(0xFF0B234F),
    secondaryContainer: Color(0xFF1E3A6E),
    onSecondaryContainer: Color(0xFFD6E4FC),
    tertiary: Color(0xFFF7BE5C),
    onTertiary: Color(0xFF3A2600),
    tertiaryContainer: Color(0xFF5C4110),
    onTertiaryContainer: Color(0xFFFCEACB),
    error: Color(0xFFEE6C60),
    onError: Color(0xFF3A0A06),
    errorContainer: Color(0xFF7A241D),
    onErrorContainer: Color(0xFFFAD9D6),
    surface: Color(0xFF0F2942),
    onSurface: Color(0xFFE7EAEE),
    surfaceContainerLowest: Color(0xFF081A2C),
    surfaceContainerLow: Color(0xFF0D243D),
    surfaceContainer: Color(0xFF122E4A),
    surfaceContainerHigh: Color(0xFF1B3A5C),
    surfaceContainerHighest: Color(0xFF244568),
    onSurfaceVariant: Color(0xFF9AACC2),
    outline: Color(0xFF2B4A6B),
    outlineVariant: Color(0xFF1E3A5A),
    inverseSurface: Color(0xFFE7EAEE),
    onInverseSurface: Color(0xFF0F2942),
    inversePrimary: Color(0xFF2E6FE0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0xFF5DE0FF),
  );

  static final _textTheme = TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600),
    titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
    bodyLarge: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
    ),
  );
}

class ThemeProvider extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const ThemeProvider({
    super.key,
    required ValueNotifier<ThemeMode> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ThemeMode read(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ThemeProvider>();
    assert(provider != null, 'No ThemeProvider found in context');
    return provider!.notifier!.value;
  }

  static void toggle(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ThemeProvider>();
    assert(provider != null, 'No ThemeProvider found in context');
    final notifier = provider!.notifier!;
    notifier.value = switch (notifier.value) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      _ => ThemeMode.system,
    };
  }

  static void setThemeMode(BuildContext context, ThemeMode mode) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ThemeProvider>();
    assert(provider != null, 'No ThemeProvider found in context');
    provider!.notifier!.value = mode;
  }
}

class FleetStatusColors extends ThemeExtension<FleetStatusColors> {
  const FleetStatusColors({
    required this.moving,
    required this.stopped,
    required this.warning,
    required this.critical,
    required this.movingBg,
    required this.stoppedBg,
    required this.warningBg,
    required this.criticalBg,
  });

  final Color moving;
  final Color stopped;
  final Color warning;
  final Color critical;
  final Color movingBg;
  final Color stoppedBg;
  final Color warningBg;
  final Color criticalBg;

  static const light = FleetStatusColors(
    moving: Color(0xFF2E6FE0),
    stopped: Color(0xFFD93025),
    warning: Color(0xFFB5790E),
    critical: Color(0xFFD93025),
    movingBg: Color(0xFFD6E4FC),
    stoppedBg: Color(0xFFFAD9D6),
    warningBg: Color(0xFFFCEACB),
    criticalBg: Color(0xFFFAD9D6),
  );

  static const dark = FleetStatusColors(
    moving: Color(0xFF5DE0FF),
    stopped: Color(0xFFEE6C60),
    warning: Color(0xFFF7BE5C),
    critical: Color(0xFFEE6C60),
    movingBg: Color(0xFF005577),
    stoppedBg: Color(0xFF7A241D),
    warningBg: Color(0xFF5C4110),
    criticalBg: Color(0xFF7A241D),
  );

  @override
  FleetStatusColors copyWith({
    Color? moving,
    Color? stopped,
    Color? warning,
    Color? critical,
    Color? movingBg,
    Color? stoppedBg,
    Color? warningBg,
    Color? criticalBg,
  }) {
    return FleetStatusColors(
      moving: moving ?? this.moving,
      stopped: stopped ?? this.stopped,
      warning: warning ?? this.warning,
      critical: critical ?? this.critical,
      movingBg: movingBg ?? this.movingBg,
      stoppedBg: stoppedBg ?? this.stoppedBg,
      warningBg: warningBg ?? this.warningBg,
      criticalBg: criticalBg ?? this.criticalBg,
    );
  }

  @override
  FleetStatusColors lerp(ThemeExtension<FleetStatusColors>? other, double t) {
    if (other is! FleetStatusColors) return this;
    return t < 0.5 ? this : other;
  }
}

class FleetSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class FleetRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const pill = 999.0;
}
