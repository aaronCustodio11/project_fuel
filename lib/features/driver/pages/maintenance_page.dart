import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project_fuel/core/models/maintenance.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/services/deliveries.dart';
import 'package:project_fuel/core/services/maintenance_service.dart';
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
  List<MaintenanceRecord> _maintenanceRecords = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _authService.getSavedUser();
    if (user != null) {
      final results = await Future.wait([
        _deliveryService.getTruckForDriver(user.userId),
        MaintenanceService().getRecords(),
      ]);
      _truck = results[0] as TruckModel?;
      final allRecords = results[1] as List<MaintenanceRecord>;
      if (_truck != null) {
        _maintenanceRecords = allRecords.where((r) => r.vehicleId == _truck!.truckId).toList();
      }
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
                  ? Center(child: LoadingAnimationWidget.staggeredDotsWave(color: theme.colorScheme.primary, size: 50))
                  : _buildContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final scheduled = _maintenanceRecords.where((r) => r.status != MaintenanceStatus.completed).toList();
    final history = _maintenanceRecords.where((r) => r.status == MaintenanceStatus.completed).toList();

    return ListView(
      padding: const EdgeInsets.all(FleetSpacing.lg),
      children: [
        _buildVehicleHeader(theme),
        const SizedBox(height: FleetSpacing.lg),
        _buildSectionTitle(theme, 'Scheduled Maintenance'),
        const SizedBox(height: FleetSpacing.sm),
        if (scheduled.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No scheduled maintenance', style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
          )
        else
          ...scheduled.map((r) => _buildMaintenanceTile(theme, r)),
        const SizedBox(height: FleetSpacing.lg),
        _buildSectionTitle(theme, 'Service History'),
        const SizedBox(height: FleetSpacing.sm),
        if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No service history', style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
          )
        else
          ...history.map((r) => _buildHistoryTile(theme, r)),
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

  Widget _buildMaintenanceTile(ThemeData theme, MaintenanceRecord record) {
    final isUrgent = record.priority == MaintenancePriority.critical || record.priority == MaintenancePriority.high;
    return Card(
      margin: const EdgeInsets.only(bottom: FleetSpacing.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isUrgent
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isUrgent ? Icons.warning_rounded : Icons.build_rounded,
            color: isUrgent
                ? theme.colorScheme.error
                : theme.colorScheme.secondary,
            size: 22,
          ),
        ),
        title: Text(
          record.type,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          record.scheduledDate != null
              ? 'Due: ${record.scheduledDate!.toString().split(' ')[0]}'
              : record.description,
          style: theme.textTheme.bodySmall,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isUrgent
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(FleetRadius.pill),
          ),
          child: Text(
            record.status.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isUrgent
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTile(ThemeData theme, MaintenanceRecord record) {
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
          record.type,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          record.completedDate != null
              ? '${record.completedDate!.toString().split(' ')[0]} • ${record.cost.toStringAsFixed(0)} PHP'
              : record.description,
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}
