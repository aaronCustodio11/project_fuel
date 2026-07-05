import 'package:chartify/chartify.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:project_fuel/core/models/fleet_tracking.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/services/json_reader.dart';
import 'package:project_fuel/core/theme/app_theme.dart';
import 'package:project_fuel/shared/widgets/role_badge.dart';

class SupplierFleetTracking extends StatefulWidget {
  const SupplierFleetTracking({super.key});

  @override
  State<SupplierFleetTracking> createState() => _SupplierFleetTrackingState();
}

class _SupplierFleetTrackingState extends State<SupplierFleetTracking> {
  final _mapController = MapController();
  final _authService = AuthenticationService();

  Object? _selectedItem;

  List<FleetTruck> _trucks = [];
  List<FleetStation> _stations = [];
  List<Map<String, dynamic>> _authUsers = [];
  bool _isLoading = true;
  LatLng? _userPosition;
  bool _followUser = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      JsonReaderService.readListStatic('assets/mock_data/vehicles.json'),
      JsonReaderService.readListStatic('assets/mock_data/stations.json'),
      JsonReaderService.readListStatic('assets/mock_data/authentication.json'),
      _authService.getSavedUser(),
    ]);

    final vehicles = results[0] as List<dynamic>;
    final stations = results[1] as List<dynamic>;
    final users = results[2] as List<dynamic>;
    final user = results[3] as AuthUser?;

    if (mounted) {
      setState(() {
        _trucks = vehicles
            .whereType<Map<String, dynamic>>()
            .map((v) => FleetTruck.fromVehicleJson(v))
            .toList();
        _stations = stations
            .whereType<Map<String, dynamic>>()
            .map((s) => FleetStation.fromJson(s))
            .toList();
        _authUsers = users.cast<Map<String, dynamic>>();
        _userPosition = (user?.latitude != null && user?.longitude != null)
            ? LatLng(user!.latitude!, user.longitude!)
            : null;
        _isLoading = false;
      });
    }
  }

  String _driverName(int? id) {
    if (id == null) return '—';
    for (final u in _authUsers) {
      if (u['userId'] == id) return '${u['firstName'] ?? ''} ${u['surName'] ?? ''}'.trim();
    }
    return '—';
  }

  void _onMapEvent(MapEvent event) {
    if ((event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) && _followUser) {
      setState(() => _followUser = false);
    }
  }

  void _centerOnUser() {
    if (_userPosition == null) return;
    _mapController.move(_userPosition!, _mapController.camera.zoom);
    setState(() => _followUser = true);
  }

  Color _truckStatusColor(TruckStatus s) => switch (s) {
    TruckStatus.moving => AppTheme.successGreen,
    TruckStatus.idle => AppTheme.warningAmber,
    TruckStatus.maintenance => AppTheme.dangerRed,
    TruckStatus.offDuty => AppTheme.neutralGray500,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: SafeArea(
        child: _isLoading
            ? Center(child: LoadingAnimationWidget.staggeredDotsWave(color: scheme.primary, size: 50))
            : _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final moving = _trucks.where((t) => t.status == TruckStatus.moving).length;
    final idle = _trucks.where((t) => t.status == TruckStatus.idle).length;
    final inMaint = _trucks.where((t) => t.status == TruckStatus.maintenance).length;
    final offDuty = _trucks.where((t) => t.status == TruckStatus.offDuty).length;

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(FleetSpacing.xl, FleetSpacing.xl, FleetSpacing.xl, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fleet Tracking', style: theme.textTheme.headlineLarge),
                Row(
                  children: [
                    _ActionButton(
                      icon: Icons.add_location_outlined,
                      label: 'Add Location',
                      color: scheme.primary,
                      onTap: _showAddLocationSheet,
                    ),
                    const SizedBox(width: FleetSpacing.sm),
                    _ActionButton(
                      icon: Icons.notifications_outlined,
                      label: 'Notify Truck',
                      color: AppTheme.accentBlue,
                      onTap: _showNotifyTruckSheet,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: FleetSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.xl),
            child: Row(
              children: [
                Expanded(child: _KpiCard(
                  label: 'Total Trucks', value: '${_trucks.length}',
                  subtitle: 'In fleet', icon: Icons.local_shipping_outlined,
                  accentColor: scheme.primary,
                )),
                const SizedBox(width: FleetSpacing.md),
                Expanded(child: _KpiCard(
                  label: 'Moving', value: '$moving',
                  subtitle: 'On route', icon: Icons.arrow_forward,
                  accentColor: AppTheme.successGreen,
                )),
                const SizedBox(width: FleetSpacing.md),
                Expanded(child: _KpiCard(
                  label: 'Idle', value: '$idle',
                  subtitle: 'Available', icon: Icons.pause_circle_outline,
                  accentColor: AppTheme.warningAmber,
                )),
                const SizedBox(width: FleetSpacing.md),
                Expanded(child: _KpiCard(
                  label: 'Maintenance', value: '$inMaint',
                  subtitle: 'In shop', icon: Icons.build_outlined,
                  accentColor: AppTheme.dangerRed,
                )),
                const SizedBox(width: FleetSpacing.md),
                Expanded(child: _KpiCard(
                  label: 'Off Duty', value: '$offDuty',
                  subtitle: 'Not available', icon: Icons.bedtime_outlined,
                  accentColor: AppTheme.neutralGray500,
                )),
              ],
            ),
          ),
          const SizedBox(height: FleetSpacing.md),
          SizedBox(
            height: 420,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(FleetRadius.lg),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: const LatLng(13.76, 121.06),
                              initialZoom: 13,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all,
                              ),
                              onMapEvent: _onMapEvent,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.project_fuel',
                              ),
                              MarkerLayer(markers: [
                                if (_userPosition != null)
                                  Marker(
                                    point: _userPosition!,
                                    width: 40,
                                    height: 40,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.person, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ..._trucks.map(_buildTruckMarker),
                                ..._stations.map(_buildStationMarker),
                              ]),
                            ],
                          ),
                        ),
                        if (_userPosition != null)
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: FloatingActionButton.small(
                              heroTag: 'locate',
                              onPressed: _centerOnUser,
                              backgroundColor: _followUser
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.surface,
                              tooltip: 'Center on my location',
                              child: Icon(
                                Icons.my_location_rounded,
                                color: _followUser
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: FleetSpacing.md),
                  SizedBox(
                    width: 320,
                    child: _DetailPanel(
                      item: _selectedItem,
                      truckStatusColor: _truckStatusColor,
                      onNotifyDriver: _showNotifyTruckSheet,
                      onDismiss: () => setState(() => _selectedItem = null),
                      driverName: _driverName,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: FleetSpacing.md),
          _buildFuelAnalytics(context),
          const SizedBox(height: FleetSpacing.md),
          _buildTruckFuelList(context),
          const SizedBox(height: FleetSpacing.xl),
        ],
      ),
    );
  }

  Marker _buildTruckMarker(FleetTruck truck) {
    final color = _truckStatusColor(truck.status);
    final selected = _selectedItem == truck;
    final size = selected ? 56.0 : 48.0;
    return Marker(
      point: truck.position,
      width: size + 8,
      height: size + 8,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        child: RoleBadge(
          icon: Icons.local_shipping_rounded,
          color: color,
          onTap: () => _onItemTap(truck),
          borderWidth: selected ? 4 : 3,
          glowOpacity: selected ? 0.6 : 0.4,
          size: selected ? 48 : 44,
        ),
      ),
    );
  }

  Marker _buildStationMarker(FleetStation station) {
    final isGas = station.type == StationType.gasStation;
    final selected = _selectedItem == station;
    final size = selected ? 56.0 : 48.0;
    return Marker(
      point: station.position,
      width: size + 8,
      height: size + 8,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        child: RoleBadge(
          icon: isGas ? Icons.local_gas_station_rounded : Icons.warehouse_outlined,
          color: isGas ? AppTheme.accentBlue : AppTheme.brandGreen,
          onTap: () => _onItemTap(station),
          borderWidth: selected ? 4 : 3,
          glowOpacity: selected ? 0.6 : 0.4,
          size: selected ? 48 : 44,
        ),
      ),
    );
  }

  void _onItemTap(Object item) {
    setState(() => _selectedItem = item);
  }

  void _showAddLocationSheet() {
    final typeNotifier = ValueNotifier<StationType>(StationType.gasStation);
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final positionNotifier = ValueNotifier<LatLng?>(null);
    final mapCtrl = MapController();

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FleetRadius.lg),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(FleetSpacing.xl),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add Location', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: FleetSpacing.lg),
                    ValueListenableBuilder<StationType>(
                      valueListenable: typeNotifier,
                      builder: (_, type, _) => Row(
                        children: [
                          Expanded(
                            child: _TypeToggle(
                              label: 'Gas Station',
                              icon: Icons.local_gas_station,
                              selected: type == StationType.gasStation,
                              onTap: () => typeNotifier.value = StationType.gasStation,
                            ),
                          ),
                          const SizedBox(width: FleetSpacing.sm),
                          Expanded(
                            child: _TypeToggle(
                              label: 'Warehouse',
                              icon: Icons.warehouse_outlined,
                              selected: type == StationType.warehouse,
                              onTap: () => typeNotifier.value = StationType.warehouse,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: FleetSpacing.md),
                    Text('Pin Location on Map', style: theme.textTheme.titleSmall),
                    const SizedBox(height: FleetSpacing.sm),
                    ValueListenableBuilder<LatLng?>(
                      valueListenable: positionNotifier,
                      builder: (_, pos, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(FleetRadius.sm),
                        child: SizedBox(
                          height: 260,
                          child: Stack(
                            children: [
                              FlutterMap(
                                mapController: mapCtrl,
                                options: MapOptions(
                                  initialCenter: const LatLng(13.76, 121.06),
                                  initialZoom: 12,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.all,
                                  ),
                                  onTap: (_, point) => positionNotifier.value = point,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.project_fuel',
                                  ),
                                  if (pos != null)
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: pos,
                                          width: 40,
                                          height: 40,
                                          child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              if (pos == null)
                                Positioned(
                                  top: 8,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Tap the map to place a pin',
                                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: FleetSpacing.md),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Location Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(FleetRadius.sm)),
                      ),
                    ),
                    const SizedBox(height: FleetSpacing.md),
                    TextField(
                      controller: addressCtrl,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(FleetRadius.sm)),
                      ),
                    ),
                    const SizedBox(height: FleetSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: FleetSpacing.sm),
                        ValueListenableBuilder<LatLng?>(
                          valueListenable: positionNotifier,
                          builder: (_, pos, _) => FilledButton(
                            onPressed: pos == null || nameCtrl.text.trim().isEmpty
                                ? null
                                : () async {
                                    final confirmed = await showDialog<bool>(
                                      context: ctx,
                                      builder: (c) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(FleetRadius.md),
                                        ),
                                        title: const Text('Confirm'),
                                        content: Text(
                                          'Add ${typeNotifier.value == StationType.gasStation ? 'Gas Station' : 'Warehouse'}'
                                          ' "${nameCtrl.text.trim()}" at this location?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(c, false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(c, true),
                                            child: const Text('Add'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed != true || !ctx.mounted) return;

                                    final station = FleetStation(
                                      id: 'STN-${(_stations.length + 1).toString().padLeft(3, '0')}',
                                      name: nameCtrl.text.trim(),
                                      position: pos,
                                      type: typeNotifier.value,
                                      address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                                      fuelLevel: typeNotifier.value == StationType.gasStation ? 1.0 : null,
                                    );
                                    setState(() => _stations.add(station));
                                    Navigator.pop(ctx);

                                    if (!context.mounted) return;
                                    showDialog(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(FleetRadius.md),
                                        ),
                                        title: const Text('Success'),
                                        content: Text(
                                          '${typeNotifier.value == StationType.gasStation ? 'Gas Station' : 'Warehouse'}'
                                          ' "${nameCtrl.text}" has been added.',
                                        ),
                                        actions: [
                                          FilledButton(
                                            onPressed: () => Navigator.pop(c),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                            child: const Text('Add Location'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNotifyTruckSheet({FleetTruck? truck}) {
    final selected = ValueNotifier<FleetTruck?>(truck);
    final msgCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FleetRadius.lg),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(FleetSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notify Truck Driver', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: FleetSpacing.lg),
                  ValueListenableBuilder<FleetTruck?>(
                    valueListenable: selected,
                    builder: (_, sel, _) => DropdownButtonFormField<FleetTruck>(
                      initialValue: sel,
                      decoration: InputDecoration(
                        labelText: 'Select Truck',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(FleetRadius.sm)),
                      ),
                      items: _trucks.map((t) => DropdownMenuItem(
                        value: t,
                        child: Text('${t.name} - ${t.plateNumber}'),
                      )).toList(),
                      onChanged: (v) => selected.value = v,
                    ),
                  ),
                  const SizedBox(height: FleetSpacing.md),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      hintText: 'Type your notification message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(FleetRadius.sm)),
                    ),
                  ),
                  const SizedBox(height: FleetSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: FleetSpacing.sm),
                      ValueListenableBuilder<FleetTruck?>(
                        valueListenable: selected,
                        builder: (_, sel, _) => FilledButton.icon(
                          onPressed: sel == null || msgCtrl.text.trim().isEmpty
                              ? null
                              : () async {
                                  final t = sel;
                                  final confirmed = await showDialog<bool>(
                                    context: ctx,
                                    builder: (c) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(FleetRadius.md),
                                      ),
                                      title: const Text('Confirm'),
                                      content: Text(
                                        'Send notification to ${t.name} (${t.plateNumber})?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(c, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(c, true),
                                          child: const Text('Send'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true || !ctx.mounted) return;

                                  Navigator.pop(ctx);

                                  if (!context.mounted) return;
                                  showDialog(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(FleetRadius.md),
                                      ),
                                      title: const Text('Success'),
                                      content: Text('Notification sent to ${t.name}.'),
                                      actions: [
                                        FilledButton(
                                          onPressed: () => Navigator.pop(c),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.send_outlined, size: 16),
                          label: const Text('Send Notification'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFuelAnalytics(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final avgFuel = _trucks.fold<double>(0, (s, t) => s + (t.fuelLevel ?? 0)) / _trucks.length;
    final lowFuel = _trucks.where((t) => (t.fuelLevel ?? 0) < 0.25).length;
    final totalFuel = _trucks.fold<double>(0, (s, t) => s + (t.fuelLevel ?? 0));
    final estRange = (avgFuel * 500).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fuel Analytics', style: theme.textTheme.titleLarge),
          const SizedBox(height: FleetSpacing.md),
          Row(
            children: [
              Expanded(child: _KpiCard(
                label: 'Avg Fuel Level', value: '${(avgFuel * 100).round()}%',
                subtitle: 'Fleet average', icon: Icons.speed,
                accentColor: scheme.primary,
              )),
              const SizedBox(width: FleetSpacing.md),
              Expanded(child: _KpiCard(
                label: 'Low Fuel Alerts', value: '$lowFuel',
                subtitle: 'Below 25%', icon: Icons.report_problem,
                accentColor: lowFuel > 0 ? AppTheme.dangerRed : AppTheme.successGreen,
              )),
              const SizedBox(width: FleetSpacing.md),
              Expanded(child: _KpiCard(
                label: 'Fleet Fuel Avg', value: '${(totalFuel / _trucks.length * 100).round()}%',
                subtitle: 'Total capacity', icon: Icons.local_gas_station,
                accentColor: AppTheme.accentBlue,
              )),
              const SizedBox(width: FleetSpacing.md),
              Expanded(child: _KpiCard(
                label: 'Est. Range', value: '$estRange km',
                subtitle: 'Fleet average', icon: Icons.route,
                accentColor: AppTheme.brandGreen,
              )),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          SizedBox(
            height: 200,
            child: _ChartCard(
              title: 'Fuel Levels by Truck',
              subtitle: 'Current fuel percentage',
              child: _buildFuelChart(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelChart(ThemeData theme) {
    final labels = _trucks.map((t) => t.name.replaceAll('Truck ', '')).toList();
    final values = _trucks.map((t) => (t.fuelLevel ?? 0) * 100).toList();

    return RepaintBoundary(
      child: BarChart(
        data: BarChartData(
          series: [
            BarSeries.fromValues<double>(
              name: 'Fuel %',
              values: values,
              color: const Color(0xFF2E6FE0),
            ),
          ],
          xAxis: BarXAxisConfig(categories: labels),
          yAxis: const BarYAxisConfig(min: 0, max: 100),
          grouping: BarGrouping.grouped,
          direction: BarDirection.vertical,
        ),
        tooltip: const TooltipConfig(enabled: true),
        animation: const ChartAnimation.none(),
      ),
    );
  }

  Widget _buildTruckFuelList(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Truck Fuel Monitoring', style: theme.textTheme.titleLarge),
              Text('${_trucks.length} trucks', style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              )),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          ..._trucks.map((truck) => Padding(
            padding: const EdgeInsets.only(bottom: FleetSpacing.md),
            child: _FuelMonitorCard(
              truck: truck,
              statusColor: _truckStatusColor(truck.status),
              driverName: _driverName(truck.driverId),
            ),
          )),
        ],
      ),
    );
  }
}

class _FuelMonitorCard extends StatelessWidget {
  final FleetTruck truck;
  final Color statusColor;
  final String driverName;

  const _FuelMonitorCard({required this.truck, required this.statusColor, this.driverName = '—'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fuelPct = (truck.fuelLevel ?? 0) * 100;
    final estRange = (truck.fuelLevel ?? 0) * 500;
    final fuelColor = fuelPct > 50
        ? AppTheme.successGreen
        : fuelPct > 25
            ? AppTheme.warningAmber
            : AppTheme.dangerRed;

    return Container(
      padding: const EdgeInsets.all(FleetSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(FleetRadius.md),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(FleetSpacing.sm),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(FleetRadius.sm),
            ),
            child: Icon(Icons.local_shipping, size: 20, color: statusColor),
          ),
          const SizedBox(width: FleetSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(truck.name, style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                          Text('${truck.plateNumber} · $driverName',
                              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: truck.status == TruckStatus.moving
                            ? AppTheme.successGreen.withValues(alpha: 0.12)
                            : truck.status == TruckStatus.idle
                                ? AppTheme.warningAmber.withValues(alpha: 0.12)
                                : truck.status == TruckStatus.maintenance
                                    ? AppTheme.dangerRed.withValues(alpha: 0.12)
                                    : AppTheme.neutralGray500.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(FleetRadius.pill),
                      ),
                      child: Text(
                        truck.status.name.replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}').trim(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FleetSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: truck.fuelLevel,
                          minHeight: 10,
                          backgroundColor: scheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(fuelColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: FleetSpacing.sm),
                    SizedBox(
                      width: 44,
                      child: Text('${fuelPct.round()}%',
                          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: fuelColor)),
                    ),
                  ],
                ),
                const SizedBox(height: FleetSpacing.sm),
                Row(
                  children: [
                    _MiniStat(label: 'Range', value: '$estRange km', icon: Icons.route, color: AppTheme.accentBlue),
                    const SizedBox(width: FleetSpacing.lg),
                    _MiniStat(label: 'Speed', value: truck.speed != null ? '${truck.speed} km/h' : '—',
                        icon: Icons.speed, color: AppTheme.warningAmber),
                    const SizedBox(width: FleetSpacing.lg),
                    _MiniStat(label: 'Updated', value: truck.lastUpdate ?? '—',
                        icon: Icons.access_time, color: scheme.onSurfaceVariant),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: FleetSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, color: color)),
          ],
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(FleetSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(FleetRadius.md),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  )),
                ],
              ),
              Icon(Icons.more_horiz, color: scheme.onSurfaceVariant, size: 18),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(FleetSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(FleetRadius.md),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(FleetSpacing.sm),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(FleetRadius.sm),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FleetRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.md, vertical: FleetSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(FleetRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: FleetSpacing.xs),
            Text(label, style: theme.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final Object? item;
  final Color Function(TruckStatus) truckStatusColor;
  final void Function({FleetTruck? truck}) onNotifyDriver;
  final VoidCallback onDismiss;
  final String Function(int?) driverName;

  const _DetailPanel({
    required this.item,
    required this.truckStatusColor,
    required this.onNotifyDriver,
    required this.onDismiss,
    required this.driverName,
  }) : assert(item == null || item is FleetTruck || item is FleetStation);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(FleetRadius.lg),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: [
          if (item != null)
            _buildDetailHeader(context)
          else
            _buildEmptyHeader(context),
          const Divider(height: 1),
          Expanded(
            child: item == null
                ? _buildEmptyState(context)
                : item is FleetTruck
                    ? _TruckDetail(
                        truck: item as FleetTruck,
                        truckStatusColor: truckStatusColor,
                        onNotifyDriver: onNotifyDriver,
                        driverName: driverName((item as FleetTruck).driverId),
                      )
                    : _StationDetail(station: item as FleetStation),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = item is FleetTruck
        ? (item as FleetTruck).name
        : (item as FleetStation).name;

    return Padding(
      padding: const EdgeInsets.fromLTRB(FleetSpacing.lg, FleetSpacing.lg, FleetSpacing.sm, FleetSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: scheme.onSurfaceVariant),
            onPressed: onDismiss,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(FleetSpacing.lg, FleetSpacing.lg, FleetSpacing.sm, FleetSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Text('Details', style: theme.textTheme.titleMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FleetSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_outlined, size: 48, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: FleetSpacing.md),
            Text('Select a marker', style: theme.textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: FleetSpacing.xs),
            Text('Tap a truck or station on the map', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _TruckDetail extends StatelessWidget {
  final FleetTruck truck;
  final Color Function(TruckStatus) truckStatusColor;
  final void Function({FleetTruck? truck}) onNotifyDriver;
  final String driverName;

  const _TruckDetail({
    required this.truck,
    required this.truckStatusColor,
    required this.onNotifyDriver,
    this.driverName = '—',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusColor = truckStatusColor(truck.status);
    final fuelPct = (truck.fuelLevel ?? 0) * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(FleetSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(label: 'Plate Number', value: truck.plateNumber),
          const SizedBox(height: FleetSpacing.md),
          _DetailRow(label: 'Driver', value: driverName),
          const SizedBox(height: FleetSpacing.md),
          _DetailRow(label: 'Speed', value: truck.speed != null ? '${truck.speed} km/h' : '—'),
          const SizedBox(height: FleetSpacing.md),
          _DetailRow(label: 'Last Update', value: truck.lastUpdate ?? '—'),
          const SizedBox(height: FleetSpacing.md),
          Row(
            children: [
              Text('Status', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(width: FleetSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(FleetRadius.sm),
                ),
                child: Text(
                  truck.status.name.replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}').trim(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: FleetSpacing.lg),
          Text('Fuel Level', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: FleetSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: truck.fuelLevel,
                    minHeight: 8,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      fuelPct > 50 ? AppTheme.successGreen : fuelPct > 20 ? AppTheme.warningAmber : AppTheme.dangerRed,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: FleetSpacing.sm),
              SizedBox(
                width: 48,
                child: Text('${fuelPct.round()}%', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: FleetSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => onNotifyDriver(truck: truck),
              icon: const Icon(Icons.notifications_outlined, size: 16),
              label: const Text('Notify Driver'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StationDetail extends StatelessWidget {
  final FleetStation station;

  const _StationDetail({required this.station});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isGas = station.type == StationType.gasStation;
    final color = isGas ? AppTheme.accentBlue : AppTheme.brandGreen;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(FleetSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGas ? Icons.local_gas_station : Icons.warehouse_outlined,
                size: 16,
                color: color,
              ),
              const SizedBox(width: FleetSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(FleetRadius.sm),
                ),
                child: Text(
                  isGas ? 'Gas Station' : 'Warehouse',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          _DetailRow(label: 'Address', value: station.address ?? '—'),
          if (isGas && station.fuelLevel != null) ...[
            const SizedBox(height: FleetSpacing.md),
            Text('Fuel Level', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: FleetSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: station.fuelLevel,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        station.fuelLevel! > 0.5 ? AppTheme.successGreen : station.fuelLevel! > 0.2 ? AppTheme.warningAmber : AppTheme.dangerRed,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: FleetSpacing.sm),
                SizedBox(
                  width: 48,
                  child: Text('${(station.fuelLevel! * 100).round()}%', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeToggle({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FleetRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: FleetSpacing.md),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(FleetRadius.sm),
          border: Border.all(color: selected ? scheme.primary : scheme.outline),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant, size: 24),
            const SizedBox(height: FleetSpacing.xs),
            Text(label, style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            )),
          ],
        ),
      ),
    );
  }
}


