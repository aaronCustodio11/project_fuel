import 'package:flutter/material.dart';
import 'package:project_fuel/features/authentication/login_screen.dart';
import 'package:project_fuel/features/authentication/splash_screen.dart';
import 'package:project_fuel/features/driver/driver_dashboard.dart';
import 'package:project_fuel/features/profile/profile_screen.dart';
import 'package:project_fuel/features/supplier/user_dashboard.dart';

import 'app_routes.dart';

class RouteGenerator {
  RouteGenerator._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(settings, const SplashScreenPage());

      case AppRoutes.login:
        return _buildRoute(settings, const LoginScreenPage());

      case AppRoutes.register:
        return _buildRoute(settings, const PlaceholderPage(title: 'Register'));

      case AppRoutes.driverHome:
        return _buildRoute(settings, const DriverDashboardPage());

      case AppRoutes.managerHome:
        return _buildRoute(
          settings,
          const PlaceholderPage(title: 'Station Manager Dashboard'),
        );

      case AppRoutes.supplierHome:
        return _buildRoute(
          settings,
          const PlaceholderPage(title: 'Supplier Dashboard'),
        );

      case AppRoutes.userDashboard:
        return _buildRoute(
          settings,
          const UserDashboard(),
        );

      case AppRoutes.profile:
        return _buildRoute(settings, const ProfileScreenPage());

      case AppRoutes.settings:
        return _buildRoute(settings, const PlaceholderPage(title: 'Settings'));

      default:
        return _buildRoute(settings, const UnknownRoutePage());
    }
  }

  static MaterialPageRoute _buildRoute(RouteSettings settings, Widget page) {
    return MaterialPageRoute(settings: settings, builder: (_) => page);
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), automaticallyImplyLeading: false,),
      body: Center(child: Text(title, style: const TextStyle(fontSize: 24))),
    );
  }
}

class UnknownRoutePage extends StatelessWidget {
  const UnknownRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('404')),
      body: const Center(
        child: Text('Page not found', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
