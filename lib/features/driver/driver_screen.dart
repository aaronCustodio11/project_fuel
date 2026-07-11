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
  Set<String> _routeDeliveryIds = {};
  Set<String> _completedDeliveryIds = {};

  void _startRoute(Set<String> deliveryIds) {
    setState(() {
      _routeDeliveryIds = deliveryIds;
      _selectedIndex = 0;
    });
  }

  void _onDeliveryCompleted(Set<String> completedIds) {
    setState(() => _completedDeliveryIds = completedIds);
  }

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
        children: [
          DriverMapPage(
            initialSelectedDeliveryIds: _routeDeliveryIds,
            completedDeliveryIds: _completedDeliveryIds,
            onDeliveryCompleted: _onDeliveryCompleted,
            onNavigationEnd: () => setState(() {
              _routeDeliveryIds = {};
              _selectedIndex = 1;
            }),
          ),
          DriverDeliveriesPage(
            activeRouteDeliveryIds: _routeDeliveryIds,
            completedDeliveryIds: _completedDeliveryIds,
            onStartRoute: _startRoute,
            onViewMap: () => setState(() => _selectedIndex = 0),
          ),
          const VehicleMaintenancePage(),
          const ProfileScreenPage(),
        ],
      ),
      bottomNavigationBar: FleetBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}
