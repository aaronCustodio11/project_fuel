import 'package:flutter/material.dart';
import 'package:project_fuel/features/authentication/pages/login_page.dart';
import 'package:project_fuel/features/authentication/pages/splash_page.dart';
import 'package:project_fuel/features/driver/driver_screen.dart';
import 'package:project_fuel/features/manager/manager_screen.dart';
import 'package:project_fuel/features/profile/pages/profile_page.dart';
import 'package:project_fuel/features/supplier/supplier_screen.dart';

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
        return _buildRoute(settings, const DriverScreen());

      case AppRoutes.managerHome:
        return _buildRoute(settings, const ManagerScreen());

      case AppRoutes.supplierHome:
        return _buildRoute(settings, const SupplierScreen());

      case AppRoutes.profile:
        return _buildRoute(settings, const ProfileScreenPage());

      case AppRoutes.settings:
        return _buildRoute(settings, const PlaceholderPage(title: 'Settings'));

      default:
        return _buildRoute(settings, const UnknownRoutePage());
    }
  }

  static Route<dynamic> _buildRoute(RouteSettings settings, Widget page) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, _, _) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
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
