# FleetSense — design theme (Flutter)

A single source of truth for colors, type, spacing, and component styling across the FleetSense dashboard and mobile app. Built as a Flutter `ThemeData` pair (light + dark) using Material 3 `ColorScheme.fromSeed` overrides.

---

## 1. Brand colors

| Token | Hex | Usage |
|---|---|---|
| `brandGreen` | `#1E8E4A` | Primary actions, active nav item, "moving/active" status, success states |
| `brandGreenDark` | `#166238` | Pressed states, dark-mode primary |
| `navyDeep` | `#0F2942` | Sidebar background, headers, dark surfaces |
| `navyMid` | `#1B3A5C` | Cards on navy, secondary dark surface |
| `accentBlue` | `#2E6FE0` | Links, chart lines, info states, map routes |
| `dangerRed` | `#D93025` | Critical alerts, theft detection, stopped vehicle |
| `warningAmber` | `#F5A623` | Warnings, low fuel, geofence exits |
| `successGreen` | `#1E8E4A` | Resolved, active, on-time |
| `neutralGray900` | `#1A1D21` | Primary text (light mode) |
| `neutralGray500` | `#6B7280` | Secondary text |
| `neutralGray200` | `#E5E7EB` | Borders, dividers (light mode) |
| `neutralGray50` | `#F7F8FA` | Page background (light mode) |

These are the *only* raw hex values in the app — everything else is generated from them or pulled from `Theme.of(context)`.

---

## 2. Flutter color scheme

### 2.1 Light mode

```dart
const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF1E8E4A),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFDCF3E4),
  onPrimaryContainer: Color(0xFF0B4423),
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
  inversePrimary: Color(0xFF7FD79B),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Color(0xFF1E8E4A),
);
```

### 2.2 Dark mode

```dart
const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF4CBB78),
  onPrimary: Color(0xFF0B2A17),
  primaryContainer: Color(0xFF1D5A38),
  onPrimaryContainer: Color(0xFFC3EED2),
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
  inversePrimary: Color(0xFF1E8E4A),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Color(0xFF4CBB78),
);
```

### 2.3 Status colors (semantic, mode-independent helpers)

Define these as a `ThemeExtension` since Material's `ColorScheme` has no native "status" slots — the app needs 4 vehicle/alert states everywhere (nav list, map pins, alert badges).

```dart
@immutable
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

  final Color moving, stopped, warning, critical;
  final Color movingBg, stoppedBg, warningBg, criticalBg;

  static const light = FleetStatusColors(
    moving: Color(0xFF1E8E4A),
    stopped: Color(0xFFD93025),
    warning: Color(0xFFB5790E),
    critical: Color(0xFFD93025),
    movingBg: Color(0xFFDCF3E4),
    stoppedBg: Color(0xFFFAD9D6),
    warningBg: Color(0xFFFCEACB),
    criticalBg: Color(0xFFFAD9D6),
  );

  static const dark = FleetStatusColors(
    moving: Color(0xFF4CBB78),
    stopped: Color(0xFFEE6C60),
    warning: Color(0xFFF7BE5C),
    critical: Color(0xFFEE6C60),
    movingBg: Color(0xFF1D5A38),
    stoppedBg: Color(0xFF7A241D),
    warningBg: Color(0xFF5C4110),
    criticalBg: Color(0xFF7A241D),
  );

  @override
  FleetStatusColors copyWith({Color? moving, Color? stopped, Color? warning,
      Color? critical, Color? movingBg, Color? stoppedBg, Color? warningBg, Color? criticalBg}) {
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
```

Usage: `Theme.of(context).extension<FleetStatusColors>()!.moving`

---

## 3. Typography

Font family: **Inter** (matches the geometric, technical feel of the mockups; falls back to system sans).

```dart
final _textTheme = TextTheme(
  displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
  headlineLarge: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.25), // page titles
  headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),                       // section headers ("Overview")
  titleLarge: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600),                           // card titles
  titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),                          // list item titles ("Truck #001")
  bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5),
  bodyMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, height: 1.5),              // default body
  labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),                           // buttons
  labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.2),      // badges, chips
  labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.3),       // timestamps, captions
);
```

Big stat numbers (e.g. "48", "2,450 L") on overview cards use `displayLarge` at a reduced size (28px) with `FontFeature.tabularFigures()` so digits align in tables/lists.

---

## 4. Spacing, radius & elevation

```dart
class FleetSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class FleetRadius {
  static const sm = 8.0;   // chips, inputs
  static const md = 12.0;  // cards
  static const lg = 16.0;  // modals, bottom sheets
  static const pill = 999.0; // status pills
}
```

- Cards: 12px radius, 1px hairline border (`outline`), **no drop shadow** in light mode (flat, like the mockups) — elevation communicated by border + subtle bg contrast only. Dark mode cards use `surfaceContainer` vs `surface` for the same flat effect.
- Nav rail / sidebar: no radius (full-bleed), `navyDeep` bg in both modes (sidebar stays dark even in light mode, matching the screenshot).
- Bottom sheets / modals: 16px top radius, `Colors.black38` scrim.

---

## 5. Component theming

### 5.1 AppBar / top bar
- Light: white bg, `neutralGray900` title text, bottom hairline border (no shadow).
- Dark: `navyDeep` bg, `onSurface` title text.

### 5.2 Navigation (sidebar on web/tablet, bottom nav on mobile)
- Always rendered in **dark navy** regardless of app theme mode (brand consistency, matches mockup) — this is the one place theme mode doesn't apply.
- Active item: `brandGreen` filled pill behind icon+label, white text.
- Inactive item: `neutralGray300`-equivalent (`#8FA3B8`) icon/text on navy.
- Mobile bottom nav: 5 items max (Overview / Tracking / Fuel / Alerts / More), active icon fills solid, inactive stays outline (Tabler-style icon set).

### 5.3 Cards (`FleetCard`)
```dart
CardThemeData(
  color: colorScheme.surface,
  surfaceTintColor: Colors.transparent, // kill M3 auto-tint, keep flat mockup look
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(FleetRadius.md),
    side: BorderSide(color: colorScheme.outline, width: 1),
  ),
  margin: EdgeInsets.zero,
)
```

### 5.4 Status badges / pills
Pill-shaped, `labelMedium` text, colored via `FleetStatusColors`:
```
[● Moving · 60 km/h]   bg: movingBg   text: moving
[■ Stopped]            bg: stoppedBg  text: stopped
[▲ Low fuel]           bg: warningBg  text: warning
[! Critical]           bg: criticalBg text: critical
```

### 5.5 Buttons
- Primary (`FilledButton`): `brandGreen` fill, white label, 8px radius — used for "Mark as Resolved", "View All Vehicles".
- Secondary (`OutlinedButton`): 1px `outline` border, transparent fill — used for filters, "View Alerts".
- Destructive: `dangerRed` fill — used for delete/deactivate actions only.
- Text button: `accentBlue` label — used for inline links like "View All".

### 5.6 Alerts / notification cards
Left-edge 4px colored bar (no radius on that edge) + icon + title + subtitle, matching the mockup's alert list:
- Critical (theft/fuel drop): red bar, `ti-alert-triangle` icon, `criticalBg` icon chip.
- Warning (geofence, low fuel): amber bar, `ti-map-pin` / `ti-gas-station` icon.
- Info: blue bar, `ti-info-circle` icon.

### 5.7 Charts
- Line charts (fuel trend, fuel level vs time): `accentBlue` line, area fill = `accentBlue` at 12% opacity, gridlines = `outlineVariant`.
- Bar/consumption charts: `brandGreen` bars.
- Map route line: `brandGreen`, vehicle pins colored by `FleetStatusColors` (moving = green truck icon, stopped = red truck icon).

### 5.8 Inputs
- Filled style, `surfaceContainerLow` background, 8px radius, no border until focused (then 1.5px `primary` border) — matches the clean search bars in the mockup ("Search vehicle…").

---

## 6. Putting it together — `ThemeData`

```dart
ThemeData buildFleetSenseTheme(Brightness brightness) {
  final scheme = brightness == Brightness.light ? _lightScheme : _darkScheme;
  final statusColors = brightness == Brightness.light
      ? FleetStatusColors.light
      : FleetStatusColors.dark;

  return ThemeData(
    useMaterial3: true,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FleetRadius.sm)),
        padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.lg, vertical: FleetSpacing.md),
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
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 0),
  );
}
```

Wire both into `MaterialApp`:

```dart
MaterialApp(
  theme: buildFleetSenseTheme(Brightness.light),
  darkTheme: buildFleetSenseTheme(Brightness.dark),
  themeMode: ThemeMode.system, // or app-level toggle
  ...
)
```

---

## 7. Icon set

Use **Tabler Icons** (`tabler_icons` or via `flutter_svg` from the outline set) for parity with the web dashboard: `ti-truck`, `ti-map-pin`, `ti-gas-station`, `ti-alert-triangle`, `ti-bell`, `ti-chart-bar`, `ti-users`, `ti-tool`, `ti-settings`. Outline weight only, 20–24px in nav/lists, 16px inline with text.

---

## 8. Quick reference swatch

| Role | Light | Dark |
|---|---|---|
| Primary | `#1E8E4A` | `#4CBB78` |
| Secondary/accent | `#2E6FE0` | `#7AA6F2` |
| Warning | `#B5790E` on `#FCEACB` | `#F7BE5C` on `#5C4110` |
| Danger | `#D93025` on `#FAD9D6` | `#EE6C60` on `#7A241D` |
| Surface | `#FFFFFF` | `#0F2942` |
| Page bg | `#F7F8FA` | `#081A2C` |
| Border | `#E5E7EB` | `#2B4A6B` |
| Text primary | `#1A1D21` | `#E7EAEE` |
| Text secondary | `#6B7280` | `#9AACC2` |
| Sidebar (always dark) | `#0F2942` | `#0F2942` |
