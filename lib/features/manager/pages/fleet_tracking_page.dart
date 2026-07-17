import 'dart:math' as math;
import 'package:chartify/chartify.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:project_fuel/core/constants/delivery_conditions.dart';
import 'package:project_fuel/core/models/fleet_tracking.dart';
import 'package:project_fuel/core/models/order.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/services/deliveries.dart';
import 'package:project_fuel/core/services/json_reader.dart';
import 'package:project_fuel/core/services/navigation_simulator.dart';
import 'package:project_fuel/core/services/order_service.dart';
import 'package:project_fuel/core/services/osrm_routing.dart';
import 'package:project_fuel/core/theme/app_theme.dart';
import 'package:project_fuel/shared/widgets/action_button.dart';
import 'package:project_fuel/shared/widgets/warning_card.dart';

class ManagerFleetTracking extends StatefulWidget {
  const ManagerFleetTracking({super.key});

  @override
  State<ManagerFleetTracking> createState() => _ManagerFleetTrackingState();
}

class _ManagerFleetTrackingState extends State<ManagerFleetTracking> {
  final _mapController = MapController();
  final _authService = AuthenticationService();
  final _deliveryService = DeliveryService();
  final _routingService = OSRMRoutingService();

  Object? _selectedItem;

  List<FleetTruck> _trucks = [];
  List<FleetStation> _stations = [];
  bool _isLoading = true;
  LatLng? _userPosition;
  bool _followUser = true;
  FleetTruck? _trackingTruck;
  List<_DeliveryStop> _trackedStops = [];
  List<LatLng>? _routePoints;
  bool _isLoadingRoute = false;

  final Map<String, NavigationSimulator> _simulators = {};
  final Map<String, LatLng> _livePositions = {};

  bool _isCreateOrderMode = false;
  FleetStation? _orderDepot;
  FleetStation? _orderStation;
  final _orderFuelTypeCtrl = TextEditingController(text: 'Diesel');
  final _orderQuantityCtrl = TextEditingController();
  DateTime _orderScheduledDate = DateTime.now().add(const Duration(days: 1));
  final _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (final s in _simulators.values) {
      s.dispose();
    }
    _simulators.clear();
    super.dispose();
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
    final user = results[3] as AuthUser?;
    final supervisorId = user?.supervisorId;

    if (mounted) {
      setState(() {
        _trucks = vehicles
            .whereType<Map<String, dynamic>>()
            .map((v) => FleetTruck.fromVehicleJson(v))
            .where((t) => supervisorId == null || t.supervisorId == supervisorId)
            .toList();
        _stations = stations
            .whereType<Map<String, dynamic>>()
            .map((s) => FleetStation.fromJson(s))
            .where((s) => supervisorId == null || s.supervisorId == supervisorId)
            .toList();
        _userPosition = (user?.latitude != null && user?.longitude != null)
            ? LatLng(user!.latitude!, user.longitude!)
            : null;
        _isLoading = false;
      });
      _startSimulations();
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToMarkers());
    }
  }

  void _fitMapToMarkers() {
    final positions = <LatLng>[
      ..._trucks.where((t) => t.position.latitude != 0 || t.position.longitude != 0).map((t) => t.position),
      ..._stations.map((s) => s.position),
      ?_userPosition,
    ];
    if (positions.isEmpty) return;
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;
    for (final p in positions) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final latPad = (maxLat - minLat) * 0.3;
    final lngPad = (maxLng - minLng) * 0.3;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat - latPad, minLng - lngPad),
          LatLng(maxLat + latPad, maxLng + lngPad),
        ),
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  void _trackTruck(FleetTruck truck) {
    _mapController.move(truck.position, 16);
    setState(() {
      _trackingTruck = truck;
      _selectedItem = truck;
      _followUser = false;
      _trackedStops = [];
      _routePoints = null;
    });
    _fetchRouteForTruck(truck);
  }

  Future<void> _fetchRouteForTruck(FleetTruck truck) async {
    final deliveries = await _deliveryService.getAllDeliveries();
    final truckDeliveries = deliveries.where((d) => d.truckId == truck.id).toList();

    if (truckDeliveries.isEmpty) return;

    final stops = <LatLng>[];
    final stopNames = <LatLng, _DeliveryStop>{};

    for (final d in truckDeliveries) {
      final pos = LatLng(d.stationLat, d.stationLng);
      stops.add(pos);
      stopNames[pos] = _DeliveryStop(
        position: pos,
        name: d.stationName,
        product: d.product,
        quantity: d.quantity,
        unit: d.unit,
      );
    }

    if (!mounted) return;
    setState(() {
      _trackedStops = stopNames.values.toList();
      _isLoadingRoute = true;
    });

    final waypoints = [truck.position, ...stops];
    final result = await _routingService.getRoute(waypoints: waypoints);

    if (!mounted) return;

    if (result != null) {
      double totalKm = 0;
      for (var i = 0; i < result.polyline.length - 1; i++) {
        totalKm += _calculateDistanceKm(result.polyline[i], result.polyline[i + 1]);
      }

      setState(() {
        _routePoints = result.polyline;
        _isLoadingRoute = false;
      });

      _showRouteLoadedNotification(truck, totalKm);
    } else {
      setState(() => _isLoadingRoute = false);
    }
  }

  double _calculateDistanceKm(LatLng a, LatLng b) {
    const earthRadius = 6371.0;
    final lat1 = a.latitude * (math.pi / 180);
    final lat2 = b.latitude * (math.pi / 180);
    final deltaLat = (b.latitude - a.latitude) * (math.pi / 180);
    final deltaLng = (b.longitude - a.longitude) * (math.pi / 180);
    final x = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    return earthRadius * 2 * math.asin(math.sqrt(x));
  }

  void _showRouteLoadedNotification(FleetTruck truck, double totalKm) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Route loaded for ${truck.name} — ${totalKm.toStringAsFixed(1)} km'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearTracking() {
    if (_userPosition != null) {
      _mapController.move(_userPosition!, 15);
    }
    setState(() {
      _trackingTruck = null;
      _selectedItem = null;
      _trackedStops = [];
      _routePoints = null;
      _followUser = true;
    });
  }

  Future<void> _startSimulations() async {
    final enRouteTrucks = _trucks.where((t) => t.status == TruckStatus.moving).toList();
    if (enRouteTrucks.isEmpty) return;

    final deliveries = await _deliveryService.getAllDeliveries();

    for (final truck in enRouteTrucks) {
      final truckDeliveries = deliveries.where((d) => d.truckId == truck.id).toList();
      if (truckDeliveries.isEmpty) continue;

      truckDeliveries.sort((a, b) {
        const order = {'inProgress': 0, 'scheduled': 1, 'completed': 2};
        return (order[a.status] ?? 3).compareTo(order[b.status] ?? 3);
      });

      final stops = <NavigationStop>[];
      for (final d in truckDeliveries) {
        if (d.status == 'completed') continue;
        stops.add(NavigationStop(
          id: d.id,
          name: d.stationName,
          position: LatLng(d.stationLat, d.stationLng),
        ));
      }
      if (stops.isEmpty) continue;

      final waypoints = [truck.position, ...stops.map((s) => s.position)];
      final result = await _routingService.getRoute(waypoints: waypoints);
      if (!mounted) return;
      if (result == null) continue;

      final speed = (truck.speed != null && truck.speed! > 0) ? truck.speed! : 40.0;

      final simulator = NavigationSimulator(
        route: result.polyline,
        stops: stops,
        speedKph: speed,
        tickMs: 2000,
        arrivalThresholdKm: 0.1,
      );

      simulator.state.addListener(() {
        if (!mounted) return;
        final navState = simulator.state.value;
        setState(() {
          _livePositions[truck.id] = navState.currentPosition;
        });
      });

      _simulators[truck.id] = simulator;
      simulator.start();
    }
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fleet Tracking', style: theme.textTheme.headlineLarge),
                    const SizedBox(height: 4),
                    Text('${_stations.length} station${_stations.length == 1 ? '' : 's'} monitored',
                        style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _isCreateOrderMode ? AppTheme.dangerRed : AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.md, vertical: FleetSpacing.sm),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FleetRadius.sm)),
                      ),
                      onPressed: () {
                        setState(() {
                          _isCreateOrderMode = !_isCreateOrderMode;
                          if (!_isCreateOrderMode) {
                            _orderDepot = null;
                            _orderStation = null;
                            _orderQuantityCtrl.clear();
                          }
                        });
                      },
                      icon: Icon(_isCreateOrderMode ? Icons.close : Icons.add_location_alt_outlined, size: 16),
                      label: Text(_isCreateOrderMode ? 'Cancel Order' : 'Create Order'),
                    ),
                    const SizedBox(width: FleetSpacing.sm),
                    ActionButton(
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
                  Expanded(child: _buildMap()),
                  const SizedBox(width: FleetSpacing.md),
                  SizedBox(width: 320, child: _buildSidePanel()),
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
    final pos = _livePositions[truck.id] ?? truck.position;
    final color = _truckStatusColor(truck.status);
    final selected = _selectedItem == truck;
    final size = selected ? 56.0 : 48.0;
    return Marker(
      point: pos,
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
          color: isGas ? AppTheme.accentBlue : AppTheme.brandBlue,
          onTap: () => _onItemTap(station),
          borderWidth: selected ? 4 : 3,
          glowOpacity: selected ? 0.6 : 0.4,
          size: selected ? 48 : 44,
        ),
      ),
    );
  }

  Marker _buildStopMarker(_DeliveryStop stop) {
    return Marker(
      point: stop.position,
      width: 46,
      height: 46,
      child: RoleBadge(
        icon: Icons.local_gas_station_rounded,
        color: AppTheme.accentBlue,
        size: 44,
      ),
    );
  }

  void _onItemTap(Object item) {
    if (_isCreateOrderMode && item is FleetStation) {
      final isDepot = item.type == StationType.depot;
      setState(() {
        if (isDepot) {
          _orderDepot = item;
        } else {
          _orderStation = item;
        }
      });
      return;
    }
    if (item is FleetTruck) {
      _trackTruck(item);
    } else {
      setState(() {
        _selectedItem = _selectedItem == item ? null : item;
        _trackingTruck = null;
      });
    }
  }

  Widget _buildMap() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(FleetRadius.lg),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(13.76, 121.06),
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onMapEvent: _onMapEvent,
            ),
            children: (() {
              var mapMarkers = <Marker>[
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
                if (_trackingTruck != null) ...[
                  _buildTruckMarker(_trackingTruck!),
                  for (final stop in _trackedStops)
                    _buildStopMarker(stop),
                ] else ...[
                  if (!_isCreateOrderMode) ..._trucks.map(_buildTruckMarker),
                  ..._stations.map(_buildStationMarker),
                ],
              ];

              final routeScheme = Theme.of(context).colorScheme;
              final routePolylines = <Polyline>[];
              if (_routePoints != null && _routePoints!.length >= 2) {
                final trackedSim = _trackingTruck != null ? _simulators[_trackingTruck!.id] : null;
                final traveled = trackedSim?.state.value.routeIndex ?? 0;
                if (traveled > 0 && traveled < _routePoints!.length) {
                  routePolylines.add(
                    Polyline(
                      points: _routePoints!.sublist(0, traveled),
                      color: routeScheme.outline.withValues(alpha: 0.3),
                      strokeWidth: 4,
                    ),
                  );
                  routePolylines.add(
                    Polyline(
                      points: _routePoints!.sublist(traveled),
                      color: routeScheme.secondary,
                      strokeWidth: 5,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2,
                    ),
                  );
                } else {
                  routePolylines.add(
                    Polyline(
                      points: _routePoints!,
                      color: routeScheme.secondary,
                      strokeWidth: 5,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2,
                    ),
                  );
                }
              }

              return <Widget>[
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.project_fuel',
                ),
                MarkerLayer(rotate: true, markers: mapMarkers),
                PolylineLayer(polylines: routePolylines),
              ];
            })(),
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
    );
  }

  Widget _buildSidePanel() {
    if (_isCreateOrderMode) {
      return _buildCreateOrderPanel();
    }

    if (_trackingTruck != null && _trackedStops.isNotEmpty) {
      final truck = _trackingTruck!;
      final totalKm = _routePoints != null
          ? (() {
              double km = 0;
              for (var i = 0; i < _routePoints!.length - 1; i++) {
                km += _calculateDistanceKm(_routePoints![i], _routePoints![i + 1]);
              }
              return km;
            })()
          : 0.0;
      return Container(
        padding: const EdgeInsets.all(FleetSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(FleetRadius.md),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tracking', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _clearTracking,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: FleetSpacing.md),
            Row(
              children: [
                RoleBadge(
                  icon: Icons.local_shipping_rounded,
                  color: _truckStatusColor(truck.status),
                  size: 40,
                ),
                const SizedBox(width: FleetSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(truck.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                      Text(truck.plateNumber, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: FleetSpacing.md),
            if (_isLoadingRoute)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: FleetSpacing.md),
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              )
            else ...[
              _detailRow(Icons.route, 'Est. Distance', '${totalKm.toStringAsFixed(1)} km'),
              const SizedBox(height: FleetSpacing.sm),
              _detailRow(Icons.location_on, 'Stops', '${_trackedStops.length}'),
              const SizedBox(height: FleetSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _clearTracking,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear Tracking'),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_selectedItem != null) {
      return _DetailPanel(
        item: _selectedItem,
        truckStatusColor: _truckStatusColor,
        onNotifyDriver: _showNotifyTruckSheet,
        onDismiss: () {
          if (_trackingTruck != null) {
            _clearTracking();
          } else {
            setState(() => _selectedItem = null);
          }
        },
      );
    }

    return _StationList(stations: _stations);
  }

  Widget _buildCreateOrderPanel() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fuelTypes = ['Diesel', 'Gasoline', 'Premium Gasoline'];

    return Container(
      padding: const EdgeInsets.all(FleetSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(FleetRadius.md),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Create Order', style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() {
                    _isCreateOrderMode = false;
                    _orderDepot = null;
                    _orderStation = null;
                    _orderQuantityCtrl.clear();
                  }),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: FleetSpacing.md),
            _buildOrderLocationTile(
              icon: Icons.warehouse_outlined,
              label: 'Fuel Source (Depot)',
              station: _orderDepot,
              color: AppTheme.brandBlue,
            ),
            const SizedBox(height: FleetSpacing.sm),
            _buildOrderLocationTile(
              icon: Icons.local_gas_station_rounded,
              label: 'Delivery Destination',
              station: _orderStation,
              color: AppTheme.accentBlue,
            ),
            const SizedBox(height: FleetSpacing.md),
            DropdownButtonFormField<String>(
              value: _orderFuelTypeCtrl.text,
              decoration: InputDecoration(
                labelText: 'Fuel Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(FleetRadius.sm)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: fuelTypes.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (v) {
                if (v != null) _orderFuelTypeCtrl.text = v;
              },
            ),
            const SizedBox(height: FleetSpacing.sm),
            TextField(
              controller: _orderQuantityCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity (L)',
                hintText: 'e.g. 5000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(FleetRadius.sm)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: FleetSpacing.sm),
            InkWell(
              onTap: () => _pickScheduledDate(),
              borderRadius: BorderRadius.circular(FleetRadius.sm),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Scheduled Date',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(FleetRadius.sm)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: FleetSpacing.sm),
                    Text(
                      '${_orderScheduledDate.month}/${_orderScheduledDate.day}/${_orderScheduledDate.year}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: FleetSpacing.md),
            if (_orderDepot != null && _orderStation != null) ...[
              WarningCard(
                message: DeliveryConditions.getWarning(
                  DeliveryConditions.mockAmbientTemp,
                  _orderFuelTypeCtrl.text,
                ),
                isActive: DeliveryConditions.hasActiveWarning(
                  DeliveryConditions.mockAmbientTemp,
                ),
              ),
              const SizedBox(height: FleetSpacing.md),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _orderDepot != null && _orderStation != null
                    ? _submitCreateOrder
                    : null,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Submit Order for Approval'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderLocationTile({
    required IconData icon,
    required String label,
    required FleetStation? station,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(FleetSpacing.md),
      decoration: BoxDecoration(
        color: station != null ? color.withValues(alpha: 0.08) : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(FleetRadius.sm),
        border: Border.all(
          color: station != null ? color.withValues(alpha: 0.3) : scheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: station != null ? color : scheme.onSurfaceVariant),
          const SizedBox(width: FleetSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                )),
                const SizedBox(height: 2),
                Text(
                  station != null ? station.name : 'Tap on map to select',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: station != null ? null : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (station != null)
            Icon(Icons.check_circle, size: 18, color: color),
        ],
      ),
    );
  }

  Future<void> _pickScheduledDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _orderScheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null && mounted) {
      setState(() => _orderScheduledDate = picked);
    }
  }

  Future<void> _submitCreateOrder() async {
    if (_orderDepot == null || _orderStation == null) return;

    final quantity = double.tryParse(_orderQuantityCtrl.text.trim());
    if (quantity == null || quantity <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid quantity'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final user = await _authService.getSavedUser();
    if (user == null || !mounted) return;

    final order = Order(
      orderId: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().padLeft(3, '0').substring(0, 3)}',
      depotId: _orderDepot!.id,
      stationId: _orderStation!.id,
      createdBy: user.userId,
      fuelType: _orderFuelTypeCtrl.text,
      quantity: quantity,
      scheduledDate: _orderScheduledDate,
      createdAt: DateTime.now(),
    );

    await _orderService.createOrder(order);

    if (!mounted) return;
    setState(() {
      _isCreateOrderMode = false;
      _orderDepot = null;
      _orderStation = null;
      _orderQuantityCtrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${order.orderId} sent for supervisor approval'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _detailRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: FleetSpacing.sm),
        Text('$label: ', style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        )),
        Expanded(
          child: Text(value, style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          )),
        ),
      ],
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
                accentColor: AppTheme.brandBlue,
              )),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          SizedBox(
            height: 380,
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

    final dataMax = values.reduce(math.max);
    final padding = dataMax * 0.15;
    final yMax = (((dataMax + padding) / 10).ceil() * 10).toDouble();

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
          yAxis: BarYAxisConfig(
            min: 0,
            max: yMax,
            labelFormatter: (value) => value.toInt().toString(),
          ),
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
            ),
          )),
        ],
      ),
    );
  }
}

class _DeliveryStop {
  final LatLng position;
  final String name;
  final String product;
  final int quantity;
  final String unit;

  const _DeliveryStop({
    required this.position,
    required this.name,
    required this.product,
    required this.quantity,
    required this.unit,
  });
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _KpiCard({required this.label, required this.value, required this.subtitle, required this.icon, required this.accentColor});

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
                child: Icon(icon, size: 18, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: FleetSpacing.xs),
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
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

class _StationList extends StatelessWidget {
  final List<FleetStation> stations;

  const _StationList({required this.stations});

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
          Text('My Stations', style: theme.textTheme.titleMedium),
          const SizedBox(height: FleetSpacing.md),
          Expanded(
            child: stations.isEmpty
                ? Center(
                    child: Text('No stations assigned',
                        style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  )
                : ListView.separated(
                    itemCount: stations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: FleetSpacing.sm),
                    itemBuilder: (_, i) {
                      final s = stations[i];
                      final isGas = s.type == StationType.gasStation;
                      return Container(
                        padding: const EdgeInsets.all(FleetSpacing.md),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(FleetRadius.sm),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isGas ? Icons.local_gas_station_rounded : Icons.warehouse_outlined,
                              size: 16,
                              color: isGas ? AppTheme.accentBlue : AppTheme.brandBlue,
                            ),
                            const SizedBox(width: FleetSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.name, style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  )),
                                  if (s.address != null)
                                    Text(s.address!, style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final Object? item;
  final Color Function(TruckStatus) truckStatusColor;
  final VoidCallback onNotifyDriver;
  final VoidCallback onDismiss;

  const _DetailPanel({
    required this.item,
    required this.truckStatusColor,
    required this.onNotifyDriver,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (item is FleetTruck) {
      final truck = item as FleetTruck;
      final fuelPct = (truck.fuelLevel ?? 0) * 100;
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
                Text('Truck Details', style: theme.textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDismiss,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: FleetSpacing.md),
            Center(
              child: RoleBadge(
                icon: Icons.local_shipping_rounded,
                color: truckStatusColor(truck.status),
                size: 64,
              ),
            ),
            const SizedBox(height: FleetSpacing.md),
            Center(
              child: Text(truck.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(truck.plateNumber, style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              )),
            ),
            const SizedBox(height: FleetSpacing.md),
            _detailRow(context, Icons.speed, 'Speed', truck.speed != null ? '${truck.speed} km/h' : '\u2014'),
            const SizedBox(height: FleetSpacing.sm),
            _detailRow(context, Icons.local_gas_station, 'Fuel', '${fuelPct.round()}%'),
            const SizedBox(height: FleetSpacing.sm),
            _detailRow(context, Icons.circle, 'Status', truck.status.name),
            const SizedBox(height: FleetSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onNotifyDriver,
                icon: const Icon(Icons.notifications_outlined, size: 16),
                label: const Text('Notify Driver'),
              ),
            ),
          ],
        ),
      );
    }

    if (item is FleetStation) {
      final station = item as FleetStation;
      final isGas = station.type == StationType.gasStation;
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
                Text('Station Details', style: theme.textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDismiss,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: FleetSpacing.md),
            Center(
              child: RoleBadge(
                icon: isGas ? Icons.local_gas_station_rounded : Icons.warehouse_outlined,
                color: isGas ? AppTheme.accentBlue : AppTheme.brandBlue,
                size: 64,
              ),
            ),
            const SizedBox(height: FleetSpacing.md),
            Center(
              child: Text(station.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
            if (station.address != null) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(station.address!, style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                )),
              ),
            ],
            const SizedBox(height: FleetSpacing.md),
            _detailRow(context, Icons.category_outlined, 'Type', isGas ? 'Gas Station' : 'Warehouse'),
            if (station.fuelLevel != null) ...[
              const SizedBox(height: FleetSpacing.sm),
              _detailRow(context, Icons.inventory, 'Stock', '${(station.fuelLevel! * 100).round()}%'),
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: FleetSpacing.sm),
        Text('$label: ', style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        )),
        Text(value, style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        )),
      ],
    );
  }
}

class RoleBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double size;
  final double borderWidth;
  final double glowOpacity;

  const RoleBadge({
    super.key,
    required this.icon,
    required this.color,
    this.onTap,
    this.size = 44,
    this.borderWidth = 3,
    this.glowOpacity = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: glowOpacity),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}

class _FuelMonitorCard extends StatelessWidget {
  final FleetTruck truck;
  final Color statusColor;

  const _FuelMonitorCard({required this.truck, required this.statusColor});

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
                          Text(truck.plateNumber,
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
                    _MiniStat(label: 'Speed', value: truck.speed != null ? '${truck.speed} km/h' : '\u2014',
                        icon: Icons.speed, color: AppTheme.warningAmber),
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
