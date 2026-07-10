import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/services/deliveries.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

class DriverDeliveriesPage extends StatefulWidget {
  final void Function(Set<String> deliveryIds)? onStartRoute;
  final Set<String> activeRouteDeliveryIds;
  final VoidCallback? onViewMap;

  const DriverDeliveriesPage({
    super.key,
    this.onStartRoute,
    this.activeRouteDeliveryIds = const {},
    this.onViewMap,
  });

  @override
  State<DriverDeliveriesPage> createState() => _DriverDeliveriesPageState();
}

class _DriverDeliveriesPageState extends State<DriverDeliveriesPage> {
  final AuthenticationService _authService = AuthenticationService();
  final DeliveryService _deliveryService = DeliveryService();

  bool _isLoading = true;
  TruckModel? _truck;
  List<DeliveryModel> _deliveries = [];
  final Set<String> _selectedDeliveryIds = {};
  bool _isSelecting = false;

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

  void _toggleDelivery(String id) {
    setState(() {
      if (_selectedDeliveryIds.contains(id)) {
        _selectedDeliveryIds.remove(id);
      } else {
        _selectedDeliveryIds.add(id);
      }
    });
  }

  Future<void> _startNavigationWithLoading() async {
    if (_selectedDeliveryIds.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingAnimationWidget.staggeredDotsWave(
                    color: Theme.of(context).colorScheme.primary,
                    size: 40,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Calculating most efficient route...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    Navigator.of(context).pop();

    widget.onStartRoute?.call(Set.from(_selectedDeliveryIds));
    setState(() {
      _isSelecting = false;
      _selectedDeliveryIds.clear();
    });
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
            if (!_isLoading) _buildBottomBar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final deliveries = _deliveries;
    var total = 0, completed = 0, enRoute = 0, pending = 0;
    for (final d in deliveries) {
      total++;
      if (d.status == 'completed') {
        completed++;
      } else if (d.status == 'inProgress') {
        enRoute++;
      } else if (d.status == 'scheduled') {
        pending++;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FleetSpacing.lg,
        FleetSpacing.lg,
        FleetSpacing.lg,
        FleetSpacing.xl * 3,
      ),
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
        _buildInfoRow(theme, Icons.speed_rounded,
            'Avg Speed', '${_truck?.speedKph ?? 0} km/h'),
        const SizedBox(height: FleetSpacing.sm),
        _buildInfoRow(theme, Icons.flight_takeoff_rounded,
            'Truck Status', widget.activeRouteDeliveryIds.isNotEmpty ? 'En Route' : (_truck?.status ?? 'Idle')),
        if (widget.activeRouteDeliveryIds.isNotEmpty) ...[
          const SizedBox(height: FleetSpacing.md),
          _buildRouteActiveBanner(theme),
        ],
        const SizedBox(height: FleetSpacing.lg),
        Text(
          _isSelecting ? 'Select destinations' : 'Delivery History',
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

  Widget _buildBottomBar(ThemeData theme) {
    if (_isSelecting) {
      final numSelected = _selectedDeliveryIds.length;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.lg, vertical: FleetSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _isSelecting = false;
                  _selectedDeliveryIds.clear();
                }),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: FleetSpacing.sm),
              Expanded(
                child: Text(
                  numSelected > 0 ? '$numSelected selected' : 'No deliveries selected',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: FleetSpacing.sm),
              SizedBox(
                height: 44,
                child: FilledButton.icon(
                  onPressed: numSelected > 0 ? _startNavigationWithLoading : null,
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: Text(numSelected > 0 ? 'Start Navigation' : 'Select deliveries'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.activeRouteDeliveryIds.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.lg, vertical: FleetSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: widget.onViewMap,
              icon: const Icon(Icons.navigation_rounded, size: 20),
              label: Text('Route active — ${widget.activeRouteDeliveryIds.length} stop${widget.activeRouteDeliveryIds.length > 1 ? 's' : ''}'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.secondaryContainer,
                foregroundColor: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.lg, vertical: FleetSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: () => setState(() => _isSelecting = true),
            icon: const Icon(Icons.route_rounded, size: 20),
            label: const Text('Start Delivery'),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteActiveBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(FleetSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(FleetRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.route_rounded, size: 20, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: FleetSpacing.sm),
          Expanded(
            child: Text(
              'Route active — ${widget.activeRouteDeliveryIds.length} destination${widget.activeRouteDeliveryIds.length > 1 ? 's' : ''}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          SizedBox(
            height: 32,
            child: FilledButton.tonalIcon(
              onPressed: widget.onViewMap,
              icon: const Icon(Icons.map_rounded, size: 16),
              label: const Text('View on Map'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
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

  void _showDeliveryDetails(DeliveryModel delivery) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final t = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.all(FleetSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(delivery.stationName, style: t.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                delivery.product,
                style: t.textTheme.bodyMedium?.copyWith(
                  color: t.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: FleetSpacing.md),
              _buildDetailRow(t, Icons.schedule_rounded, 'Status', delivery.statusLabel),
              if (delivery.sourceStationName.isNotEmpty)
                _buildDetailRow(t, Icons.warehouse_rounded, 'Source', delivery.sourceStationName),
              if (delivery.stationType.isNotEmpty)
                _buildDetailRow(t, Icons.category_rounded, 'Type', delivery.stationType == 'depot' ? 'Depot' : 'Gas Station'),
              if (delivery.scheduledDate != null)
                _buildDetailRow(t, Icons.calendar_today_rounded, 'Scheduled',
                    '${delivery.scheduledDate!.month}/${delivery.scheduledDate!.day}/${delivery.scheduledDate!.year}'),
              if (delivery.completedDate != null)
                _buildDetailRow(t, Icons.check_circle_outline_rounded, 'Completed',
                    '${delivery.completedDate!.month}/${delivery.completedDate!.day}/${delivery.completedDate!.year}'),
              if (delivery.notes.isNotEmpty)
                _buildDetailRow(t, Icons.notes_rounded, 'Notes', delivery.notes),
              const SizedBox(height: FleetSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FleetSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildDeliveryTile(ThemeData theme, DeliveryModel delivery) {
    final isSelected = _selectedDeliveryIds.contains(delivery.id);
    final isCompleted = delivery.status == 'completed';

    Color statusColor;
    IconData statusIcon;
    switch (delivery.status) {
      case 'completed':
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.check_circle_rounded;
      case 'inProgress':
        statusColor = AppTheme.warningAmber;
        statusIcon = Icons.local_shipping_rounded;
      default:
        statusColor = theme.colorScheme.onSurfaceVariant;
        statusIcon = Icons.schedule_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: FleetSpacing.sm),
      color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (_isSelecting && !isCompleted) {
            _toggleDelivery(delivery.id);
          } else {
            _showDeliveryDetails(delivery);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(FleetSpacing.md),
          child: Row(
            children: [
              if (_isSelecting && !isCompleted)
                Padding(
                  padding: const EdgeInsets.only(right: FleetSpacing.sm),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleDelivery(delivery.id),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  delivery.stationType == 'warehouse'
                      ? Icons.warehouse_rounded
                      : Icons.local_gas_station_rounded,
                  size: 20,
                  color: isCompleted
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary,
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
                        color: isCompleted
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      delivery.product,
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
                      delivery.statusLabel,
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
      ),
    );
  }
}
