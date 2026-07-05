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
  void didUpdateWidget(Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      _controller.selectIndex(widget.initialIndex);
    }
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
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        FleetSpacing.sm,
        0,
        FleetSpacing.sm,
        extended ? FleetSpacing.md : FleetSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, color: scheme.outlineVariant),
          SizedBox(height: extended ? FleetSpacing.sm : FleetSpacing.xs),

          _FooterButton(
            extended: extended,
            icon: themeIcon,
            label: themeLabel,
            onTap: () => ThemeProvider.toggle(context),
            extendedBuilder: () => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(themeIcon, color: fg, size: 16),
                const SizedBox(width: FleetSpacing.sm),
                Text(
                  themeLabel,
                  style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            collapsedBuilder: () => Icon(themeIcon, color: fg, size: 18),
          ),

          SizedBox(height: extended ? FleetSpacing.xs : 2),

          _FooterButton(
            extended: extended,
            icon: Icons.logout,
            label: 'Logout',
            onTap: () async {
              final confirmed = await showLogoutConfirmationDialog(context);
              if (confirmed && context.mounted) {
                await AuthenticationService().logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
                }
              }
            },
            isDestructive: true,
            extendedBuilder: () => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout, color: AppTheme.dangerRed, size: 16),
                const SizedBox(width: FleetSpacing.sm),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: AppTheme.dangerRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            collapsedBuilder: () => Icon(Icons.logout, color: AppTheme.dangerRed, size: 18),
          ),
        ],
      ),
    );
  }
}

class _FooterButton extends StatefulWidget {
  final bool extended;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget Function() extendedBuilder;
  final Widget Function() collapsedBuilder;
  final bool isDestructive;

  const _FooterButton({
    required this.extended,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.extendedBuilder,
    required this.collapsedBuilder,
    this.isDestructive = false,
  });

  @override
  State<_FooterButton> createState() => _FooterButtonState();
}

class _FooterButtonState extends State<_FooterButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = widget.isDestructive
        ? AppTheme.dangerRed.withValues(alpha: _isHovered ? 0.12 : 0.0)
        : scheme.surfaceContainerHighest.withValues(alpha: _isHovered ? 0.5 : 0.0);

    return Tooltip(
      message: widget.label,
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(FleetRadius.sm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: widget.extended ? FleetSpacing.md : FleetSpacing.sm,
              vertical: FleetSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(FleetRadius.sm),
            ),
            child: widget.extended ? widget.extendedBuilder() : widget.collapsedBuilder(),
          ),
        ),
      ),
    );
  }
}

