import 'package:flutter/material.dart';
import 'package:project_fuel/features/profile/pages/profile_page.dart';
import 'package:project_fuel/features/supervisor/pages/dashboard_page.dart';
import 'package:project_fuel/features/supervisor/pages/fleet_tracking_page.dart';
import 'package:project_fuel/features/supervisor/pages/fuel_monitoring_page.dart';
import 'package:project_fuel/features/supervisor/pages/theft_detection_page.dart';
import 'package:project_fuel/features/supervisor/pages/user_dashboard_page.dart';
import 'package:project_fuel/shared/widgets/sidebar.dart';
import 'package:project_fuel/shared/widgets/onboarding.dart';
import 'package:sidebarx/sidebarx.dart';

class SupervisorScreen extends StatefulWidget {
  const SupervisorScreen({super.key});

  @override
  State<SupervisorScreen> createState() => _SupervisorScreenState();
}

class _SupervisorScreenState extends State<SupervisorScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showOnboardingOverlay(context, role: OnboardingRole.supervisor);
    });
  }

  late final List<Widget> _pages = [
    SupervisorDashboard(onNavigate: _onNavigate),
    const UserDashboard(),
    const SupervisorFuelMonitoring(),
    const SupervisorFleetTracking(),
    const SupervisorTheftDetection(),
    const ProfileView(isDesktop: true),
  ];

  void _onNavigate(int index) => setState(() => _selectedIndex = index);

  static const _sidebarItems = [
    SidebarXItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    SidebarXItem(icon: Icons.people_outline, label: 'User Dashboard'),
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
