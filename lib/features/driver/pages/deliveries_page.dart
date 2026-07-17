import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project_fuel/core/models/order.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/services/deliveries.dart';
import 'package:project_fuel/core/services/order_service.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

class DriverDeliveriesPage extends StatefulWidget {
  final void Function(Set<String> deliveryIds)? onStartRoute;
  final Set<String> activeRouteDeliveryIds;
  final Set<String> completedDeliveryIds;
  final VoidCallback? onViewMap;

  const DriverDeliveriesPage({
    super.key,
    this.onStartRoute,
    this.activeRouteDeliveryIds = const {},
    this.completedDeliveryIds = const {},
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
  bool _showHistory = false;
  List<Order> _availableOrders = [];
  final _orderService = OrderService();

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
        _orderService.getOrdersByStatus(OrderStatus.approved),
      ]);
      _truck = results[0] as TruckModel?;
      _deliveries = results[1] as List<DeliveryModel>;
      _availableOrders = results[2] as List<Order>;
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

  String _effectiveStatus(DeliveryModel d) =>
      widget.completedDeliveryIds.contains(d.id) ? 'completed' : d.status;

  Widget _buildContent(ThemeData theme) {
    final deliveries = _deliveries;
    final activeDeliveries = <DeliveryModel>[];
    final historyDeliveries = <DeliveryModel>[];
    for (final d in deliveries) {
      if (_effectiveStatus(d) == 'completed') {
        historyDeliveries.add(d);
      } else {
        activeDeliveries.add(d);
      }
    }

    final completedCount =
        deliveries.where((d) => _effectiveStatus(d) == 'completed').length;
    final enRouteCount =
        deliveries.where((d) => _effectiveStatus(d) == 'inProgress').length;
    final pendingCount =
        deliveries.where((d) => _effectiveStatus(d) == 'scheduled').length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        FleetSpacing.lg,
        FleetSpacing.lg,
        FleetSpacing.lg,
        FleetSpacing.xl * 3,
      ),
      children: [
        if (_availableOrders.isNotEmpty) ...[
          _buildAvailableOrdersSection(theme),
          const SizedBox(height: FleetSpacing.lg),
        ],
        Text(
          'Delivery Overview',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: FleetSpacing.md),
        Row(
          children: [
            _buildStatCard(theme, 'Total', '${deliveries.length}', Icons.inventory_2_rounded,
                theme.colorScheme.secondaryContainer),
            const SizedBox(width: FleetSpacing.sm),
            _buildStatCard(theme, 'Completed', '$completedCount',
                Icons.check_circle_rounded, AppTheme.successGreen.withValues(alpha: 0.15)),
          ],
        ),
        const SizedBox(height: FleetSpacing.sm),
        Row(
          children: [
            _buildStatCard(theme, 'En Route', '$enRouteCount',
                Icons.local_shipping_rounded, theme.colorScheme.tertiaryContainer),
            const SizedBox(width: FleetSpacing.sm),
            _buildStatCard(theme, 'Pending', '$pendingCount',
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
        if (_isSelecting) ...[
          Text(
            'Select destinations',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: FleetSpacing.sm),
          ...activeDeliveries.map((d) => _buildDeliveryTile(theme, d)),
        ] else ...[
          Text(
            'Active Deliveries',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: FleetSpacing.sm),
          if (activeDeliveries.isNotEmpty)
            ...activeDeliveries.map((d) => _buildDeliveryTile(theme, d))
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No active deliveries',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: FleetSpacing.lg),
          _buildHistorySection(theme, historyDeliveries),
        ],
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

  Widget _buildAvailableOrdersSection(ThemeData theme) {
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.receipt_long_outlined, size: 18, color: AppTheme.accentBlue),
            const SizedBox(width: FleetSpacing.sm),
            Text(
              'Available Orders (${_availableOrders.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: FleetSpacing.sm),
        Text(
          'Approved orders awaiting your acceptance',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: FleetSpacing.sm),
        ..._availableOrders.map((order) => Padding(
          padding: const EdgeInsets.only(bottom: FleetSpacing.sm),
          child: _buildAvailableOrderTile(theme, order),
        )),
      ],
    );
  }

  Widget _buildAvailableOrderTile(ThemeData theme, Order order) {
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(FleetSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(FleetRadius.md),
        border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.receipt_outlined, size: 16, color: AppTheme.accentBlue),
              ),
              const SizedBox(width: FleetSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderId, style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    )),
                    Text(
                      '${order.quantity.round()}L ${order.fuelType}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 36,
                child: FilledButton.icon(
                  onPressed: () => _acceptOrder(order),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Accept'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _acceptOrder(Order order) async {
    final user = await _authService.getSavedUser();
    if (user == null || _truck == null || !mounted) return;

    final updated = order.copyWith(
      status: OrderStatus.accepted,
      acceptedBy: user.userId,
      acceptedAt: DateTime.now(),
    );

    await _orderService.updateOrder(updated);

    await _deliveryService.createDeliveriesFromOrder(
      updated,
      _truck!.truckId,
    );

    if (!mounted) return;

    if (!mounted) return;
    final deliveries = await _deliveryService.getDeliveriesForDriver(user.userId);
    final available = await _orderService.getOrdersByStatus(OrderStatus.approved);

    if (!mounted) return;
    setState(() {
      _deliveries = deliveries;
      _availableOrders = available;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${order.orderId} accepted — added to your deliveries'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _buildHistorySection(ThemeData theme, List<DeliveryModel> history) {
    if (history.isEmpty) return const SizedBox.shrink();

    const previewCount = 3;
    final isCollapsed = !_showHistory;
    final displayList = isCollapsed ? history.take(previewCount).toList() : history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _showHistory = !_showHistory),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  'Delivery History (${history.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(
                  isCollapsed ? Icons.expand_more : Icons.expand_less,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: FleetSpacing.sm),
        ...displayList.map((d) => _buildDeliveryTile(theme, d)),
        if (isCollapsed && history.length > previewCount)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: () => setState(() => _showHistory = true),
              icon: const Icon(Icons.expand_more, size: 18),
              label: Text('Show all (${history.length})'),
            ),
          )
        else if (!isCollapsed && history.length > previewCount)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: () => setState(() => _showHistory = false),
              icon: const Icon(Icons.expand_less, size: 18),
              label: const Text('Show less'),
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
              _buildDetailRow(t, Icons.schedule_rounded, 'Status',
                  _effectiveStatus(delivery) == 'completed'
                      ? 'Completed'
                      : _effectiveStatus(delivery) == 'inProgress'
                          ? 'In Progress'
                          : 'Scheduled'),
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
    final effectiveStatus = _effectiveStatus(delivery);
    final isCompleted = effectiveStatus == 'completed';

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (effectiveStatus) {
      case 'completed':
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Completed';
      case 'inProgress':
        statusColor = AppTheme.warningAmber;
        statusIcon = Icons.local_shipping_rounded;
        statusLabel = 'In Progress';
      default:
        statusColor = theme.colorScheme.onSurfaceVariant;
        statusIcon = Icons.schedule_rounded;
        statusLabel = 'Scheduled';
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
                  color: isCompleted
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primaryContainer,
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
                      statusLabel,
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
