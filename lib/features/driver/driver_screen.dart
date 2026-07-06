import 'package:flutter/material.dart';
import 'package:project_fuel/features/driver/pages/map_page.dart';
import 'package:project_fuel/features/driver/pages/deliveries_page.dart';
import 'package:project_fuel/features/driver/pages/maintenance_page.dart';
import 'package:project_fuel/features/profile/pages/profile_page.dart';
import 'package:project_fuel/shared/widgets/bottom_nav_bar.dart';
import 'package:project_fuel/shared/widgets/onboarding.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DriverMapPage(),
    VehicleMaintenancePage(),
    DriverDeliveriesPage(),
    ProfileScreenPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showOnboardingOverlay(context, role: OnboardingRole.driver);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: FleetBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}
