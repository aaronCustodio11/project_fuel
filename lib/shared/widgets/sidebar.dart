import 'package:flutter/material.dart';
import 'package:project_fuel/core/theme/app_theme.dart';
import 'package:sidebarx/sidebarx.dart';


class Sidebar extends StatefulWidget {
  const Sidebar({super.key, this.onItemSelected});

  /// Called with the selected index whenever the user taps a nav item.
  final ValueChanged<int>? onItemSelected;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  late final SidebarXController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SidebarXController(selectedIndex: 0, extended: true);
    _controller.addListener(_handleSelectionChange);
  }

  void _handleSelectionChange() {
    widget.onItemSelected?.call(_controller.selectedIndex);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleSelectionChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canvasColor = isDark ? AppTheme.navyDeep : AppTheme.navyDeep;
    final selectedColor = scheme.primary;
    final unselectedIconColor = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.7);

    return SidebarX(
      controller: _controller,
      theme: SidebarXTheme(
        margin: const EdgeInsets.all(FleetSpacing.sm),
        decoration: BoxDecoration(
          color: canvasColor,
          borderRadius: BorderRadius.circular(FleetRadius.lg),
        ),
        hoverColor: AppTheme.navyMid,
        textStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        hoverTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        itemTextPadding: const EdgeInsets.only(left: FleetSpacing.md),
        selectedItemTextPadding: const EdgeInsets.only(left: FleetSpacing.md),
        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FleetRadius.sm),
        ),
        selectedItemDecoration: BoxDecoration(
          color: selectedColor,
          borderRadius: BorderRadius.circular(FleetRadius.sm),
          boxShadow: [
            BoxShadow(
              color: selectedColor.withValues(alpha: 0.35),
              blurRadius: 10,
            ),
          ],
        ),
        iconTheme: IconThemeData(
          color: unselectedIconColor,
          size: 20,
        ),
        selectedIconTheme: const IconThemeData(
          color: Colors.white,
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
      ),
      extendedTheme: SidebarXTheme(
        width: 240,
        decoration: BoxDecoration(
          color: canvasColor,
          borderRadius: BorderRadius.circular(FleetRadius.lg),
        ),
      ),
      headerBuilder: (context, extended) {
        return SizedBox(
          height: 100,
          child: Padding(
            padding: const EdgeInsets.all(FleetSpacing.lg),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.primary,
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                if (extended) ...[
                  const SizedBox(width: FleetSpacing.sm),
                  const Expanded(
                    child: Text(
                      'FleetSense',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      footerBuilder: (context, extended) {
        return Padding(
          padding: const EdgeInsets.all(FleetSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.logout, color: Colors.white70, size: 18),
              if (extended) ...[
                const SizedBox(width: FleetSpacing.sm),
                const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ],
          ),
        );
      },
      items: const [
        SidebarXItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
        SidebarXItem(icon: Icons.people_outline, label: 'Users'),
        SidebarXItem(icon: Icons.local_shipping_outlined, label: 'Fleet'),
        SidebarXItem(icon: Icons.settings_outlined, label: 'Settings'),
      ],
    );
  }
}