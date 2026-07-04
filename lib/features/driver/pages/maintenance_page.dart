import 'package:flutter/material.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/services/deliveries.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

class VehicleMaintenancePage extends StatefulWidget {
  const VehicleMaintenancePage({super.key});

  @override
  State<VehicleMaintenancePage> createState() => _VehicleMaintenancePageState();
}

class _VehicleMaintenancePageState extends State<VehicleMaintenancePage> {
  final AuthenticationService _authService = AuthenticationService();
  final DeliveryService _deliveryService = DeliveryService();

  bool _isLoading = true;
  TruckModel? _truck;

  @override
  void initState() {
    super.initState();
    _loadTruck();
  }

  Future<void> _loadTruck() async {
    final user = await _authService.getSavedUser();
    if (user != null) {
      _truck = await _deliveryService.getTruckForDriver(user.userId);
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(FleetSpacing.xl, FleetSpacing.xl, FleetSpacing.xl, 0),
              child: Text('Vehicle Maintenance', style: theme.textTheme.headlineLarge),
            ),
            const SizedBox(height: FleetSpacing.md),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(FleetSpacing.lg),
      children: [
        _buildVehicleHeader(theme),
        const SizedBox(height: FleetSpacing.lg),
        _buildSectionTitle(theme, 'Scheduled Maintenance'),
        const SizedBox(height: FleetSpacing.sm),
        ..._mockMaintenanceTasks.map((t) => _buildMaintenanceTile(theme, t)),
        const SizedBox(height: FleetSpacing.lg),
        _buildSectionTitle(theme, 'Service History'),
        const SizedBox(height: FleetSpacing.sm),
        ..._mockServiceHistory.map((s) => _buildHistoryTile(theme, s)),
      ],
    );
  }

  Widget _buildVehicleHeader(ThemeData theme) {
    final truck = _truck;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(FleetSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_shipping_rounded,
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: FleetSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    truck?.plateNumber ?? 'N/A',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    truck?.truckId ?? 'No truck assigned',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (truck != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: truck.status == 'En Route'
                      ? AppTheme.successGreen.withValues(alpha: 0.15)
                      : theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(FleetRadius.pill),
                ),
                child: Text(
                  truck.status,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: truck.status == 'En Route'
                        ? AppTheme.successGreen
                        : theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMaintenanceTile(ThemeData theme, _MaintenanceTask task) {
    return Card(
      margin: const EdgeInsets.only(bottom: FleetSpacing.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: task.urgent
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            task.urgent ? Icons.warning_rounded : Icons.build_rounded,
            color: task.urgent
                ? theme.colorScheme.error
                : theme.colorScheme.secondary,
            size: 22,
          ),
        ),
        title: Text(
          task.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          task.dueDate,
          style: theme.textTheme.bodySmall,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: task.urgent
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(FleetRadius.pill),
          ),
          child: Text(
            task.status,
            style: theme.textTheme.labelSmall?.copyWith(
              color: task.urgent
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTile(ThemeData theme, _ServiceRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: FleetSpacing.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.check_circle_outline,
            color: theme.colorScheme.onSurfaceVariant,
            size: 22,
          ),
        ),
        title: Text(
          record.service,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${record.date} • ${record.odometer} km',
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _MaintenanceTask {
  final String title;
  final String dueDate;
  final String status;
  final bool urgent;

  const _MaintenanceTask({
    required this.title,
    required this.dueDate,
    required this.status,
    this.urgent = false,
  });
}

class _ServiceRecord {
  final String service;
  final String date;
  final int odometer;

  const _ServiceRecord({
    required this.service,
    required this.date,
    required this.odometer,
  });
}

const _mockMaintenanceTasks = [
  _MaintenanceTask(
    title: 'Oil Change',
    dueDate: 'Due in 500 km',
    status: 'Upcoming',
  ),
  _MaintenanceTask(
    title: 'Tire Rotation',
    dueDate: 'Due in 1,200 km',
    status: 'Upcoming',
  ),
  _MaintenanceTask(
    title: 'Brake Inspection',
    dueDate: 'Overdue by 300 km',
    status: 'Overdue',
    urgent: true,
  ),
  _MaintenanceTask(
    title: 'Engine Tune-up',
    dueDate: 'Due in 3,000 km',
    status: 'Scheduled',
  ),
];

const _mockServiceHistory = [
  _ServiceRecord(service: 'Oil Change', date: '2026-05-15', odometer: 45200),
  _ServiceRecord(service: 'Air Filter Replacement', date: '2026-04-02', odometer: 44100),
  _ServiceRecord(service: 'Tire Rotation', date: '2026-03-10', odometer: 43200),
  _ServiceRecord(service: 'Brake Pad Replacement', date: '2026-01-22', odometer: 41500),
];
