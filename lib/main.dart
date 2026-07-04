import 'package:flutter/material.dart';
import 'package:project_fuel/core/routes/app_routes.dart';
import 'package:project_fuel/core/routes/route_generator.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

void main() {
  runApp(const ProjectFuelApp());
}

class ProjectFuelApp extends StatelessWidget {
  const ProjectFuelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FleetSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.userDashboard,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
