import 'package:flutter/material.dart';
import 'package:water_drop_nav_bar/water_drop_nav_bar.dart';

class FleetBottomNavBar extends StatelessWidget {
  const FleetBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.barItems,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<BarItem>? barItems;

  static final _driverItems = [
    BarItem(
      filledIcon: Icons.map_rounded,
      outlinedIcon: Icons.map_outlined,
    ),
    BarItem(
      filledIcon: Icons.local_shipping_rounded,
      outlinedIcon: Icons.local_shipping_outlined,
    ),
    BarItem(
      filledIcon: Icons.assessment_rounded,
      outlinedIcon: Icons.assessment_outlined,
    ),
    BarItem(
      filledIcon: Icons.person_rounded,
      outlinedIcon: Icons.person_outline,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WaterDropNavBar(
      backgroundColor: theme.colorScheme.surface,
      waterDropColor: theme.colorScheme.primary,
      onItemSelected: onItemSelected,
      selectedIndex: selectedIndex,
      bottomPadding: 24,
      barItems: barItems ?? _driverItems,
    );
  }
}
