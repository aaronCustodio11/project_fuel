import 'package:flutter/material.dart';
import 'package:project_fuel/core/routes/app_routes.dart';
import 'package:project_fuel/core/theme/app_theme.dart';
import 'package:sidebarx/sidebarx.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key, this.onItemSelected, this.initialIndex = 0});

  final ValueChanged<int>? onItemSelected;
  final int initialIndex;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  static bool _isExtended = true;

  late final SidebarXController _controller;
  late int _lastIndex;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.initialIndex;
    _controller = SidebarXController(selectedIndex: widget.initialIndex, extended: _isExtended);
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (!mounted) return;
    _isExtended = _controller.extended;
    final index = _controller.selectedIndex;
    if (index == _lastIndex) return;
    _lastIndex = index;

    widget.onItemSelected?.call(index);

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.supplierHome);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.userDashboard);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.supplierMaintenance);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.supplierFleetTracking);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.supplierTheftDetection);
        break;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: SidebarX(
        controller: _controller,
        animationDuration: const Duration(milliseconds: 400),
        theme: SidebarXTheme(
          margin: const EdgeInsets.all(FleetSpacing.sm),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(FleetRadius.lg),
          ),
          hoverColor: scheme.surfaceContainerHighest,
          textStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 14,
          ),
          selectedTextStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          hoverTextStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 14,
          ),
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
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
            size: 20,
          ),
          selectedIconTheme: IconThemeData(
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
        ),
        extendedTheme: const SidebarXTheme(width: 240),
        headerBuilder: (context, extended) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.successGreen,
                    child: Icon(
                      Icons.local_shipping_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
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
        },
        footerBuilder: (context, extended) {
          return Padding(
            padding: const EdgeInsets.all(FleetSpacing.md),
            child: InkWell(
              onTap: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              },
              borderRadius: BorderRadius.circular(FleetRadius.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
                      size: 18),
                  if (extended) ...[
                    const SizedBox(width: FleetSpacing.sm),
                    Text(
                      'Logout',
                      style: TextStyle(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
                          fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        items: const [
          SidebarXItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
          SidebarXItem(icon: Icons.people_outline, label: 'User Dashboard'),
          SidebarXItem(icon: Icons.build_outlined, label: 'Maintenance'),
          SidebarXItem(icon: Icons.map_outlined, label: 'Fleet Tracking'),
          SidebarXItem(icon: Icons.security_outlined, label: 'Theft Detection'),
        ],
      ),
    );
  }
}
