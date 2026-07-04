import 'package:flutter/material.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

class ManagerFuelMonitoring extends StatelessWidget {
  const ManagerFuelMonitoring({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(FleetSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fuel Monitoring', style: theme.textTheme.headlineLarge),
              const SizedBox(height: FleetSpacing.md),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_gas_station_outlined, size: 64, color: scheme.onSurfaceVariant),
                      const SizedBox(height: FleetSpacing.md),
                      Text(
                        'Fuel Monitoring',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: FleetSpacing.sm),
                      Text(
                        'Coming soon',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
