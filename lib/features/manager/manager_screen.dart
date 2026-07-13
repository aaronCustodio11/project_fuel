import 'package:flutter/material.dart';
import 'package:project_fuel/features/manager/pages/dashboard_page.dart';
import 'package:project_fuel/features/manager/pages/fleet_tracking_page.dart';
import 'package:project_fuel/features/manager/pages/fuel_monitoring_page.dart';
import 'package:project_fuel/features/manager/pages/theft_detection_page.dart';
import 'package:project_fuel/features/profile/pages/profile_page.dart';
import 'package:project_fuel/shared/widgets/sidebar.dart';
import 'package:project_fuel/shared/widgets/onboarding.dart';
import 'package:sidebarx/sidebarx.dart';

class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    ManagerDashboard(onNavigate: (i) => setState(() => _selectedIndex = i)),
    const ManagerFuelMonitoring(),
    const ManagerFleetTracking(),
    const ManagerTheftDetection(),
    const ProfileView(isDesktop: true),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showOnboardingOverlay(context, role: OnboardingRole.manager);
    });
  }

  static const _sidebarItems = [
    SidebarXItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    SidebarXItem(icon: Icons.local_gas_station_outlined, label: 'Fuel Monitoring'),
    SidebarXItem(icon: Icons.map_outlined, label: 'Fleet Tracking'),
    SidebarXItem(icon: Icons.security_outlined, label: 'Theft Detection'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            initialIndex: _selectedIndex,
            onItemSelected: (i) => setState(() => _selectedIndex = i),
            onAccountTap: () => setState(() => _selectedIndex = _pages.length - 1),
            isAccountSelected: _selectedIndex == _pages.length - 1,
            items: _sidebarItems,
          ),
          Expanded(
            child: RepaintBoundary(
              child: IndexedStack(
                index: _selectedIndex,
                children: _pages,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
