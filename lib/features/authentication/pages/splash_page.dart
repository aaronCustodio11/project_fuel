import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project_fuel/core/routes/app_routes.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  @override
  void initState() {
    super.initState();
    _redirectAfterStartup();
  }

  Future<void> _redirectAfterStartup() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final authService = AuthenticationService();
    final savedUser = await authService.getSavedUser();

    if (!mounted) return;

    final route = savedUser == null
        ? AppRoutes.login
        : authService.getRouteForRole(savedUser.role);

    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primary.withValues(alpha: 0.85), scheme.primary],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_gas_station,
                size: 88,
                color: scheme.onPrimary,
              ),
              const SizedBox(height: FleetSpacing.lg),
              Text(
                'FleetSense',
                style: textTheme.displayLarge?.copyWith(
                  color: scheme.onPrimary,
                ),
              ),
              const SizedBox(height: FleetSpacing.sm),
              Text(
                'Fuel delivery coordination made simple',
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: FleetSpacing.xl),
              LoadingAnimationWidget.staggeredDotsWave(
                color: scheme.onPrimary,
                size: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
