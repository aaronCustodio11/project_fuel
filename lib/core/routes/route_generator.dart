import 'package:flutter/material.dart';

import 'app_routes.dart';

class RouteGenerator {
  RouteGenerator._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(
          settings,
          const PlaceholderPage(title: 'Splash Screen'),
        );

      case AppRoutes.login:
        return _buildRoute(
          settings,
          const PlaceholderPage(title: 'Login'),
        );

      case AppRoutes.register:
        return _buildRoute(
          settings,
          const PlaceholderPage(title: 'Register'),
        );

      case AppRoutes.driverHome:
        return _buildRoute(
          settings,
          const PlaceholderPage(title: 'Driver Dashboard'),
        );

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

      case AppRoutes.profile:
        return _buildRoute(
          settings,
          const PlaceholderPage(title: 'Profile'),
        );

      case AppRoutes.settings:
        return _buildRoute(
          settings,
          const PlaceholderPage(title: 'Settings'),
        );

      default:
        return _buildRoute(
          settings,
          const UnknownRoutePage(),
        );
    }
  }

  static MaterialPageRoute _buildRoute(
    RouteSettings settings,
    Widget page,
  ) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => page,
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

class UnknownRoutePage extends StatelessWidget {
  const UnknownRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('404'),
      ),
      body: const Center(
        child: Text(
          'Page not found',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}