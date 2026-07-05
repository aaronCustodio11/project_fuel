import 'package:flutter/material.dart';
import 'package:project_fuel/features/supplier/pages/dashboard_page.dart';
import 'package:project_fuel/features/supplier/pages/fleet_tracking_page.dart';
import 'package:project_fuel/features/supplier/pages/maintenance_page.dart';
import 'package:project_fuel/features/supplier/pages/theft_detection_page.dart';
import 'package:project_fuel/features/supplier/pages/user_dashboard_page.dart';
import 'package:project_fuel/shared/widgets/sidebar.dart';
import 'package:project_fuel/shared/widgets/introductory.dart';
import 'package:sidebarx/sidebarx.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showIntroductoryOverlay(context, role: IntroductoryRole.supplier);
    });
  }

  late final List<Widget> _pages = [
    SupplierDashboard(onNavigate: _onNavigate),
    const UserDashboard(),
    const SupplierMaintenance(),
    const SupplierFleetTracking(),
    const SupplierTheftDetection(),
  ];

  void _onNavigate(int index) => setState(() => _selectedIndex = index);

  static const _sidebarItems = [
    SidebarXItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    SidebarXItem(icon: Icons.people_outline, label: 'User Dashboard'),
    SidebarXItem(icon: Icons.build_outlined, label: 'Maintenance'),
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
