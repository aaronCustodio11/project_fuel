import 'package:flutter/material.dart';
import 'package:project_fuel/core/routes/app_routes.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/theme/app_theme.dart';
import 'package:project_fuel/shared/widgets/logout_dialog.dart';
import 'package:sidebarx/sidebarx.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key, this.onItemSelected, this.initialIndex = 0, required this.items});

  final ValueChanged<int>? onItemSelected;
  final int initialIndex;
  final List<SidebarXItem> items;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _isExtended = true;
  bool _themeBuilt = false;

  late final SidebarXController _controller;
  late int _lastIndex;
  late SidebarXTheme _cachedTheme;
  Brightness _lastBrightness = Brightness.light;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.initialIndex;
    _controller = SidebarXController(selectedIndex: widget.initialIndex, extended: _isExtended);
    _controller.addListener(_onChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).colorScheme.brightness;
    if (!_themeBuilt || _lastBrightness != brightness) {
      _lastBrightness = brightness;
      _cachedTheme = _buildTheme(Theme.of(context).colorScheme);
      _themeBuilt = true;
      if (mounted) setState(() {});
    }
  }

  void _onChanged() {
    if (!mounted) return;
    _isExtended = _controller.extended;
    final index = _controller.selectedIndex;
    if (index == _lastIndex) return;
    _lastIndex = index;

    widget.onItemSelected?.call(index);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  SidebarXTheme _buildTheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final fg = isDark ? Colors.white : Colors.black;

    return SidebarXTheme(
      margin: const EdgeInsets.all(FleetSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(FleetRadius.lg),
      ),
      hoverColor: scheme.surfaceContainerHighest,
      textStyle: TextStyle(color: fg, fontSize: 14),
      selectedTextStyle: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 14),
      hoverTextStyle: TextStyle(color: fg, fontSize: 14),
      itemTextPadding: const EdgeInsets.only(left: FleetSpacing.md),
      selectedItemTextPadding: const EdgeInsets.only(left: FleetSpacing.md),
      itemDecoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(FleetRadius.sm),
      ),
      selectedItemDecoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(FleetRadius.sm),
      ),
      iconTheme: IconThemeData(
        color: fg.withValues(alpha: 0.7),
        size: 20,
      ),
      selectedIconTheme: const IconThemeData(
        color: AppTheme.successGreen,
        size: 20,
      ),
      itemMargin: const EdgeInsets.symmetric(
        horizontal: FleetSpacing.sm,
        vertical: FleetSpacing.xs,
      ),
      selectedItemMargin: const EdgeInsets.symmetric(
        horizontal: FleetSpacing.sm,
        vertical: FleetSpacing.xs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _lastBrightness == Brightness.dark;
    final fg = isDark ? Colors.white : Colors.black;

    return RepaintBoundary(
      child: SidebarX(
        controller: _controller,
        animationDuration: Duration.zero,
        theme: _cachedTheme,
        extendedTheme: const SidebarXTheme(width: 240),
        headerBuilder: _buildHeader,
        footerBuilder: (context, extended) => _buildFooter(context, extended, fg),
        items: widget.items,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool extended) {
    final isDark = _lastBrightness == Brightness.dark;

    return SizedBox(
      height: 100,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.successGreen,
              child: Icon(Icons.local_shipping_outlined, color: Colors.white, size: 18),
            ),
            if (extended) ...[
              const SizedBox(height: FleetSpacing.xs),
              Text(
                'FleetSense',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool extended, Color fg) {
    final themeMode = ThemeProvider.read(context);
    final isLight = themeMode == ThemeMode.light ||
        (themeMode == ThemeMode.system && _lastBrightness == Brightness.light);
    final themeIcon = isLight ? Icons.dark_mode_outlined : Icons.light_mode_outlined;
    final themeLabel = isLight ? 'Dark' : 'Light';

    return Padding(
      padding: EdgeInsets.all(extended ? FleetSpacing.md : FleetSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => ThemeProvider.toggle(context),
            borderRadius: BorderRadius.circular(FleetRadius.sm),
            child: extended
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(themeIcon, color: fg.withValues(alpha: 0.7), size: 18),
                      const SizedBox(width: FleetSpacing.sm),
                      Flexible(
                        child: Text(
                          themeLabel,
                          style: TextStyle(color: fg.withValues(alpha: 0.7), fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Icon(themeIcon, color: fg.withValues(alpha: 0.7), size: 18),
          ),
          SizedBox(height: extended ? FleetSpacing.sm : FleetSpacing.xs),
          InkWell(
            onTap: () async {
              final confirmed = await showLogoutConfirmationDialog(context);
              if (confirmed && context.mounted) {
                await AuthenticationService().logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
                }
              }
            },
            borderRadius: BorderRadius.circular(FleetRadius.sm),
            child: extended
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout, color: fg.withValues(alpha: 0.7), size: 18),
                      const SizedBox(width: FleetSpacing.sm),
                      Flexible(
                        child: Text(
                          'Logout',
                          style: TextStyle(color: fg.withValues(alpha: 0.7), fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Icon(Icons.logout, color: fg.withValues(alpha: 0.7), size: 18),
          ),
        ],
      ),
    );
  }
}
