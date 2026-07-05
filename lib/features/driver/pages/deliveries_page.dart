import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/services/deliveries.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

class DriverDeliveriesPage extends StatefulWidget {
  const DriverDeliveriesPage({super.key});

  @override
  State<DriverDeliveriesPage> createState() => _DriverDeliveriesPageState();
}

class _DriverDeliveriesPageState extends State<DriverDeliveriesPage> {
  final AuthenticationService _authService = AuthenticationService();
  final DeliveryService _deliveryService = DeliveryService();

  bool _isLoading = true;
  TruckModel? _truck;
  List<DeliveryModel> _deliveries = [];

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
        _deliveryService.getDeliveriesForDriver(user.userId),
      ]);
      _truck = results[0] as TruckModel?;
      _deliveries = results[1] as List<DeliveryModel>;
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
              child: Text('Deliveries', style: theme.textTheme.headlineLarge),
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
    final deliveries = _deliveries;
    final total = deliveries.length;
    final completed = deliveries.where((d) => d.status == 'Completed').length;
    final enRoute = deliveries.where((d) => d.status == 'inProgress').length;
    final pending = deliveries.where((d) => d.status == 'scheduled').length;
    final totalLiters = deliveries.fold<int>(0, (sum, d) => sum + d.quantity);

    return ListView(
      padding: const EdgeInsets.all(FleetSpacing.lg),
      children: [
        Text(
          'Delivery Overview',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: FleetSpacing.md),
        Row(
          children: [
            _buildStatCard(theme, 'Total', '$total', Icons.inventory_2_rounded,
                theme.colorScheme.secondaryContainer),
            const SizedBox(width: FleetSpacing.sm),
            _buildStatCard(theme, 'Completed', '$completed',
                Icons.check_circle_rounded, AppTheme.successGreen.withValues(alpha: 0.15)),
          ],
        ),
        const SizedBox(height: FleetSpacing.sm),
        Row(
          children: [
            _buildStatCard(theme, 'En Route', '$enRoute',
                Icons.local_shipping_rounded, theme.colorScheme.tertiaryContainer),
            const SizedBox(width: FleetSpacing.sm),
            _buildStatCard(theme, 'Pending', '$pending',
                Icons.schedule_rounded, theme.colorScheme.surfaceContainerHighest),
          ],
        ),
        const SizedBox(height: FleetSpacing.lg),
        _buildInfoRow(theme, Icons.local_gas_station_rounded,
            'Total Volume', '$totalLiters L'),
        const SizedBox(height: FleetSpacing.sm),
        _buildInfoRow(theme, Icons.speed_rounded,
            'Avg Speed', '${_truck?.speedKph ?? 0} km/h'),
        const SizedBox(height: FleetSpacing.sm),
        _buildInfoRow(theme, Icons.flight_takeoff_rounded,
            'Truck Status', _truck?.status ?? 'N/A'),
        const SizedBox(height: FleetSpacing.lg),
        Text(
          'Delivery History',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: FleetSpacing.sm),
        ...deliveries.map((d) => _buildDeliveryTile(theme, d)),
        if (deliveries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No deliveries found',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color bgColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(FleetSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(FleetRadius.md),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: FleetSpacing.sm),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(FleetSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(FleetRadius.md),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: FleetSpacing.md),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTile(ThemeData theme, DeliveryModel delivery) {
    Color statusColor;
    IconData statusIcon;
    switch (delivery.status) {
      case 'Completed':
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.check_circle_rounded;
      case 'En Route':
        statusColor = AppTheme.warningAmber;
        statusIcon = Icons.local_shipping_rounded;
      default:
        statusColor = theme.colorScheme.onSurfaceVariant;
        statusIcon = Icons.schedule_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: FleetSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(FleetSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.local_gas_station_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: FleetSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    delivery.stationName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${delivery.product} • ${delivery.quantity} L',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(FleetRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    delivery.status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
