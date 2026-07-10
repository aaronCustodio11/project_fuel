import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/services/deliveries.dart';
import 'package:project_fuel/core/services/navigation_simulator.dart';
import 'package:project_fuel/core/services/osrm_routing.dart';
import 'package:project_fuel/shared/widgets/role_badge.dart';

class DriverMapPage extends StatefulWidget {
  final Set<String> initialSelectedDeliveryIds;
  final VoidCallback? onNavigationEnd;

  const DriverMapPage({super.key, this.initialSelectedDeliveryIds = const {}, this.onNavigationEnd});

  @override
  State<DriverMapPage> createState() => _DriverMapPageState();
}

class _DriverMapPageState extends State<DriverMapPage> {
  final MapController _mapController = MapController();
  final AuthenticationService _authService = AuthenticationService();
  final DeliveryService _deliveryService = DeliveryService();
  final OSRMRoutingService _routingService = OSRMRoutingService();

  bool _isLoading = true;
  String _userName = 'Driver';
  LatLng? _driverPosition;
  TruckModel? _truck;
  List<DeliveryModel> _driverDeliveries = [];
  List<LatLng>? _routePoints;
  Set<String> _selectedDeliveryIds = {};
  bool _isNavigating = false;
  NavigationSimulator? _simulator;
  String? _notificationMessage;
  Set<int> _completedStops = {};
  double _remainingKm = 0;
  int _etaMinutes = 0;
  bool _followDriver = true;
  bool _headingUp = true;
  double _rotationDegrees = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedDeliveryIds = widget.initialSelectedDeliveryIds;
    _initAsync();
  }

  @override
  void didUpdateWidget(DriverMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelectedDeliveryIds != oldWidget.initialSelectedDeliveryIds &&
        widget.initialSelectedDeliveryIds.isNotEmpty) {
      _selectedDeliveryIds = widget.initialSelectedDeliveryIds;
      if (!_isLoading) {
        _startNavigation();
      }
    }
  }

  @override
  void dispose() {
    _simulator?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  List<LatLng> _orderByNearestNeighbor(LatLng start, List<LatLng> stops) {
    if (stops.length < 2) return stops;

    final ordered = <LatLng>[];
    final remaining = stops.toList();
    var current = start;

    while (remaining.isNotEmpty) {
      var nearestIdx = 0;
      var nearestDist = double.infinity;
      for (var i = 0; i < remaining.length; i++) {
        final dist = _calculateDistanceKm(current, remaining[i]);
        if (dist < nearestDist) {
          nearestDist = dist;
          nearestIdx = i;
        }
      }
      final next = remaining.removeAt(nearestIdx);
      ordered.add(next);
      current = next;
    }

    return ordered;
  }

  Future<void> _initAsync() async {
    final user = await _authService.getSavedUser();

    if (user != null) {
      _userName = user.fullName.isEmpty ? 'Driver' : user.fullName;

      _truck = await _deliveryService.getTruckForDriver(user.userId);
      if (_truck != null && (_truck!.latitude != 0 || _truck!.longitude != 0)) {
        _driverPosition = LatLng(_truck!.latitude, _truck!.longitude);
      } else if (user.latitude != null && user.longitude != null) {
        _driverPosition = LatLng(user.latitude!, user.longitude!);
      }

      _driverDeliveries = await _deliveryService.getDeliveriesForDriver(user.userId);

      if (_selectedDeliveryIds.isNotEmpty) {
        _startNavigation();
      }
    }

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(_driverPosition ?? const LatLng(13.76, 121.06), 14.0);
      _mapController.rotate(0.0);
    });

    setState(() => _isLoading = false);
  }

  void _startNavigation() async {
    if (_selectedDeliveryIds.isEmpty || _driverPosition == null) return;

    final selected = _driverDeliveries
        .where((d) => _selectedDeliveryIds.contains(d.id))
        .toList();
    if (selected.isEmpty) return;

    final sources = <LatLng>[];
    final seenSources = <String>{};
    final destinations = <LatLng>[];
    final stops = <NavigationStop>[];

    for (final d in selected) {
      if ((d.sourceStationLat != 0 || d.sourceStationLng != 0) &&
          d.sourceStationId.isNotEmpty) {
        final key = '${d.sourceStationLat},${d.sourceStationLng}';
        if (!seenSources.contains(key)) {
          seenSources.add(key);
          sources.add(LatLng(d.sourceStationLat, d.sourceStationLng));
        }
      }
      if (d.stationLat != 0 || d.stationLng != 0) {
        destinations.add(LatLng(d.stationLat, d.stationLng));
        stops.add(NavigationStop(
          id: d.id,
          name: d.stationName,
          position: LatLng(d.stationLat, d.stationLng),
        ));
      }
    }

    final sourcesFiltered = sources.where((s) {
      final dist = _calculateDistanceKm(_driverPosition!, s);
      return dist > 0.1;
    }).toList();

    final orderedSources = sourcesFiltered.length < 2
        ? sourcesFiltered
        : _orderByNearestNeighbor(_driverPosition!, sourcesFiltered);
    final orderedDests = destinations.length < 2
        ? destinations
        : _orderByNearestNeighbor(
            orderedSources.isNotEmpty ? orderedSources.last : _driverPosition!,
            destinations,
          );

    final waypoints = [
      _driverPosition!,
      ...orderedSources,
      ...orderedDests,
    ];

    setState(() => _isNavigating = true);

    final result = await _routingService.getRoute(waypoints: waypoints);

    if (!mounted || result == null) return;

    setState(() => _routePoints = result.polyline);

    _mapController.move(_driverPosition!, 19.0);

    _simulator = NavigationSimulator(
      route: result.polyline,
      stops: stops,
      speedKph: 45,
      tickMs: 1000,
    );

    _simulator!.state.addListener(_onSimulatorTick);
    _simulator!.start();
  }

  void _onSimulatorTick() {
    if (!mounted || _simulator == null) return;
    final s = _simulator!.state.value;

    setState(() {
      _driverPosition = s.currentPosition;
      _completedStops = s.completedStopIndices;
      _remainingKm = s.remainingDistanceKm;
      _etaMinutes = s.etaMinutes;
      _notificationMessage = s.notification;

      if (_followDriver) {
        _mapController.move(s.currentPosition, _mapController.camera.zoom);
        if (_headingUp && _routePoints != null) {
          final idx = s.routeIndex;
          if (idx < _routePoints!.length - 1) {
            final heading = _computeHeading(_routePoints![idx], _routePoints![idx + 1]);
            _mapController.rotate(-heading);
            _rotationDegrees = -heading;
          }
        }
      }

      if (s.isComplete) {
        _simulator!.dispose();
        _simulator = null;
      }
    });
  }

  void _endNavigation() {
    _simulator?.dispose();
    _simulator = null;
    setState(() {
      _isNavigating = false;
      _routePoints = null;
      _selectedDeliveryIds = {};
      _completedStops = {};
      _notificationMessage = null;
      _remainingKm = 0;
      _etaMinutes = 0;
    });
    widget.onNavigationEnd?.call();
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventRotateEnd) {
      setState(() => _rotationDegrees = _mapController.camera.rotation);
    }
    if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
      setState(() => _rotationDegrees = _mapController.camera.rotation);
      if (_followDriver) {
        setState(() => _followDriver = false);
      }
    }
  }

  double _calculateDistanceKm(LatLng a, LatLng b) {
    const earthRadius = 6371.0;
    final lat1 = a.latitude * (math.pi / 180);
    final lat2 = b.latitude * (math.pi / 180);
    final deltaLat = (b.latitude - a.latitude) * (math.pi / 180);
    final deltaLng = (b.longitude - a.longitude) * (math.pi / 180);
    final x = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
  }

  double _computeHeading(LatLng from, LatLng to) {
    final dLng = (to.longitude - from.longitude) * (math.pi / 180);
    final lat1 = from.latitude * (math.pi / 180);
    final lat2 = to.latitude * (math.pi / 180);
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return math.atan2(y, x) * (180 / math.pi);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: theme.colorScheme.primary,
            size: 50,
          ),
        ),
      );
    }

    var markers = <Marker>[];

    if (_driverPosition != null) {
      markers.add(
        Marker(
          point: _driverPosition!,
          width: 50,
          height: 50,
          child: RoleBadge(
            role: 'driver',
            size: 50,
            tooltip: _userName,
          ),
        ),
      );
    }

    final deliveries = _isNavigating && _selectedDeliveryIds.isNotEmpty
        ? _driverDeliveries.where((d) => _selectedDeliveryIds.contains(d.id)).toList()
        : _driverDeliveries;

    final seenSources = <String>{};
    for (final d in deliveries) {
      if ((d.sourceStationLat != 0 || d.sourceStationLng != 0) &&
          d.sourceStationId.isNotEmpty) {
        final key = '${d.sourceStationLat},${d.sourceStationLng}';
        if (!seenSources.contains(key)) {
          seenSources.add(key);
          markers.add(
            Marker(
              point: LatLng(d.sourceStationLat, d.sourceStationLng),
              width: 46,
              height: 46,
              child: RoleBadge(
                size: 46,
                color: const Color(0xFF1565C0),
                icon: Icons.warehouse_rounded,
                tooltip: d.sourceStationName,
              ),
            ),
          );
        }
      }

      if (d.stationLat != 0 || d.stationLng != 0) {
        markers.add(
          Marker(
            point: LatLng(d.stationLat, d.stationLng),
            width: 46,
            height: 46,
            child: RoleBadge(
              size: 46,
              color: Colors.orangeAccent,
              icon: Icons.local_gas_station_rounded,
              tooltip: d.stationName,
            ),
          ),
        );
      }
    }


    final tileUrl = theme.brightness == Brightness.dark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    final polylines = <Polyline>[];

    if (_routePoints != null && _routePoints!.isNotEmpty) {
      final traveled = _simulator != null ? _simulator!.state.value.routeIndex : 0;
      if (traveled > 0 && traveled < _routePoints!.length) {
        polylines.add(
          Polyline(
            points: _routePoints!.sublist(0, traveled),
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            strokeWidth: 4,
          ),
        );
        polylines.add(
          Polyline(
            points: _routePoints!.sublist(traveled),
            color: theme.colorScheme.secondary,
            strokeWidth: 5,
            borderColor: Colors.white,
            borderStrokeWidth: 2,
          ),
        );
      } else {
        polylines.add(
          Polyline(
            points: _routePoints!,
            color: theme.colorScheme.secondary,
            strokeWidth: 5,
            borderColor: Colors.white,
            borderStrokeWidth: 2,
          ),
        );
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _driverPosition ?? const LatLng(13.76, 121.06),
              initialZoom: 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onMapEvent: _onMapEvent,
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.example.project_fuel',
              ),
              MarkerLayer(rotate: true, markers: markers),
              PolylineLayer(polylines: polylines),
            ],
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          if (_notificationMessage != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildNotification(theme),
            ),
          if (_isNavigating)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _buildNavCard(theme),
            ),
          Positioned(
            right: 16,
            bottom: _isNavigating ? 190 : 24,
            child: _buildMapControls(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildNotification(ThemeData theme) {
    final isFinal = _notificationMessage == 'All stops completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isFinal
            ? theme.colorScheme.primary
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isFinal ? Icons.check_circle : Icons.location_on_rounded,
            size: 20,
            color: isFinal
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _notificationMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isFinal
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls(ThemeData theme) {
    final showCompass = !_headingUp && _rotationDegrees.abs() >= 0.5;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          opacity: showCompass ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton.small(
            heroTag: 'compass',
            onPressed: () {
              _mapController.rotate(0.0);
              setState(() => _rotationDegrees = 0.0);
            },
            backgroundColor: theme.colorScheme.surface,
            child: Transform.rotate(
              angle: -_rotationDegrees * (math.pi / 180),
              child: const Text(
                'N',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _isNavigating
            ? FloatingActionButton.extended(
                heroTag: 'locate',
                onPressed: () {
                  if (_driverPosition == null) return;
                  double heading = 0.0;
                  if (_simulator != null && _routePoints != null) {
                    final idx = _simulator!.state.value.routeIndex;
                    if (idx < _routePoints!.length - 1) {
                      heading = _computeHeading(_routePoints![idx], _routePoints![idx + 1]);
                    }
                  }
                  _mapController.move(_driverPosition!, 19.0);
                  _mapController.rotate(-heading);
                  setState(() {
                    _followDriver = true;
                    _headingUp = true;
                    _rotationDegrees = 0.0;
                  });
                },
                backgroundColor: _followDriver
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                icon: Icon(
                  Icons.navigation_rounded,
                  color: _followDriver
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                  size: 20,
                ),
                label: Text(
                  'Re-center',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _followDriver
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
                ),
              )
            : FloatingActionButton.small(
                heroTag: 'locate',
                onPressed: () {
                  if (_driverPosition == null) return;
                  _mapController.move(_driverPosition!, _mapController.camera.zoom);
                  setState(() {
                    _followDriver = true;
                    _headingUp = true;
                    _rotationDegrees = 0.0;
                  });
                },
                backgroundColor: _followDriver
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                tooltip: 'Center on driver',
                child: Icon(
                  Icons.my_location_rounded,
                  color: _followDriver
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                ),
              ),
      ],
    );
  }

  Widget _buildNavCard(ThemeData theme) {
    if (_simulator == null && _remainingKm == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text('Calculating route...', style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    final isComplete = _notificationMessage == 'All stops completed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _completedStops.isNotEmpty
                      ? Icons.navigation_rounded
                      : Icons.route_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isComplete
                          ? 'All deliveries completed'
                          : _completedStops.isNotEmpty
                              ? 'Navigating to next stop'
                              : 'En route to destination',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_remainingKm.toStringAsFixed(1)} km • $_etaMinutes min',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (_completedStops.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${_completedStops.length} stop${_completedStops.length > 1 ? 's' : ''} completed',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!isComplete) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _endNavigation,
                icon: const Icon(Icons.stop_circle_outlined, size: 16),
                label: const Text('End navigation'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


