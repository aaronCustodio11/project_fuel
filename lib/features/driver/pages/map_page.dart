import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/services/deliveries.dart';
import 'package:project_fuel/core/services/osrm_routing.dart';
import 'package:project_fuel/shared/widgets/role_badge.dart';

class DriverMapPage extends StatefulWidget {
  const DriverMapPage({super.key});

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
  List<_DeliveryStop> _deliveryStops = [];
  List<LatLng>? _routePoints;
  _NavigationInfo? _navigationInfo;

  bool _stopsExpanded = true;
  int _routeProgress = 0;
  Set<int> _completedStops = {};
  Timer? _simulationTimer;
  String? _notificationMessage;

  bool _followDriver = true;

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
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

      if (user.latitude != null && user.longitude != null) {
        _driverPosition = LatLng(user.latitude!, user.longitude!);
      }

      final deliveries = await _deliveryService.getDeliveriesForDriver(user.userId);

      if (deliveries.isNotEmpty) {
        final rawStops = deliveries
            .where((d) => d.stationLat != 0 || d.stationLng != 0)
            .map((d) => LatLng(d.stationLat, d.stationLng))
            .toList();

        final orderedPositions = _orderByNearestNeighbor(
          _driverPosition ?? rawStops.first,
          rawStops,
        );

        final nameMap = <LatLng, String>{};
        for (final d in deliveries) {
          nameMap[LatLng(d.stationLat, d.stationLng)] = d.stationName;
        }

        _deliveryStops = orderedPositions
            .asMap()
            .entries
            .map((e) => _DeliveryStop(
                  position: e.value,
                  name: nameMap[e.value] ?? 'Stop ${e.key + 1}',
                  stopNumber: e.key + 1,
                  totalStops: orderedPositions.length,
                ))
            .toList();
      }
    }

    if (_driverPosition != null && _deliveryStops.isNotEmpty) {
      final waypoints = [
        _driverPosition!,
        ..._deliveryStops.map((s) => s.position),
      ];
      await _fetchRoute(waypoints);
    }

    if (!mounted) return;

    if (_driverPosition != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(_driverPosition!, 14.0);
        _mapController.rotate(0.0);
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _fetchRoute(List<LatLng> waypoints) async {
    final result = await _routingService.getRoute(waypoints: waypoints);

    if (!mounted) return;

    if (result != null) {
      final distanceKm = _calculateRouteDistance(result.polyline);
      final etaMinutes = (distanceKm / 45 * 60).round().clamp(3, 90);
      final firstStop = _deliveryStops.isNotEmpty ? _deliveryStops.first : null;

      setState(() {
        _routePoints = result.polyline;
        _navigationInfo = _NavigationInfo(
          instruction: distanceKm < 0.3
              ? 'Arrive at ${firstStop?.name ?? "destination"}'
              : 'Next: ${firstStop?.name ?? "destination"}',
          distanceKm: distanceKm,
          etaMinutes: etaMinutes,
          stopLabel: firstStop != null
              ? 'Stop ${firstStop.stopNumber} of ${firstStop.totalStops}'
              : null,
        );
      });

      _startSimulation();
    } else {
      double totalKm = 0;
      for (var i = 0; i < waypoints.length - 1; i++) {
        totalKm += _calculateDistanceKm(waypoints[i], waypoints[i + 1]);
      }
      final etaMinutes = (totalKm / 45 * 60).round().clamp(3, 90);
      final firstStop = _deliveryStops.isNotEmpty ? _deliveryStops.first : null;

      if (mounted) {
        setState(() {
          _routePoints = null;
          _navigationInfo = _NavigationInfo(
            instruction: 'Next: ${firstStop?.name ?? "destination"}',
            distanceKm: totalKm,
            etaMinutes: etaMinutes,
            stopLabel: firstStop != null
                ? 'Stop ${firstStop.stopNumber} of ${firstStop.totalStops}'
                : null,
          );
        });
      }
    }
  }

  void _startSimulation() {
    if (_routePoints == null || _routePoints!.length < 2) return;

    _routeProgress = 0;
    _completedStops = {};
    _followDriver = true;

    const tickMs = 800;
    _simulationTimer = Timer.periodic(const Duration(milliseconds: tickMs), (_) {
      if (!mounted) {
        _simulationTimer?.cancel();
        return;
      }
      _advanceSimulation();
    });
  }

  void _advanceSimulation() {
    if (_routePoints == null || _routeProgress >= _routePoints!.length - 1) {
      _simulationTimer?.cancel();
      return;
    }

    _routeProgress++;
    _driverPosition = _routePoints![_routeProgress];

    for (var i = 0; i < _deliveryStops.length; i++) {
      final dist = _calculateDistanceKm(
          _driverPosition!, _deliveryStops[i].position);
      if (dist < 0.05 && !_completedStops.contains(i)) {
        _completedStops = {..._completedStops, i};
        _showStopNotification(_deliveryStops[i]);
      }
    }

    final remaining = _routePoints!.sublist(_routeProgress);
    final remainingKm = _calculateRouteDistance(remaining);
    final etaMinutes = (remainingKm / 45 * 60).round().clamp(1, 90);

    final nextIdx = _deliveryStops.indexWhere(
      (s) => !_completedStops.contains(_deliveryStops.indexOf(s)),
    );
    final nextStop = nextIdx != -1 ? _deliveryStops[nextIdx] : null;

    _navigationInfo = _NavigationInfo(
      instruction: nextStop != null
          ? 'Next: ${nextStop.name}'
          : 'All stops completed',
      distanceKm: remainingKm,
      etaMinutes: etaMinutes,
      stopLabel: nextStop != null
          ? 'Stop ${nextStop.stopNumber} of ${nextStop.totalStops}'
          : null,
    );

    if (_followDriver && _driverPosition != null) {
      _mapController.move(_driverPosition!, _mapController.camera.zoom);
    }

    if (remainingKm < 0.05 && nextStop == null) {
      _simulationTimer?.cancel();
      _showArrivedNotification();
    }

    setState(() {});
  }

  void _showStopNotification(_DeliveryStop stop) {
    _notificationMessage = 'Arrived at ${stop.name}';
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        if (_notificationMessage == 'Arrived at ${stop.name}') {
          _notificationMessage = null;
        }
      });
    });
  }

  void _showArrivedNotification() {
    _notificationMessage = 'All deliveries completed';
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _notificationMessage = null);
    });
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
      if (_followDriver) {
        setState(() => _followDriver = false);
      }
    }
  }

  void _centerOnDriver() {
    if (_driverPosition == null) return;
    _mapController.move(_driverPosition!, _mapController.camera.zoom);
    setState(() => _followDriver = true);
  }

  double _calculateRouteDistance(List<LatLng> route) {
    double total = 0;
    for (var i = 0; i < route.length - 1; i++) {
      total += _calculateDistanceKm(route[i], route[i + 1]);
    }
    return total;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(child: LoadingAnimationWidget.staggeredDotsWave(color: theme.colorScheme.primary, size: 50)),
      );
    }

    final markers = <Marker>[];

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

    for (final stop in _deliveryStops) {
      markers.add(
        Marker(
          point: stop.position,
          width: 46,
          height: 46,
          child: RoleBadge(
            role: 'station',
            size: 46,
            tooltip: '${stop.stopNumber}. ${stop.name}',
          ),
        ),
      );
    }

    final tileUrl = theme.brightness == Brightness.dark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    final polylines = <Polyline>[];

    if (_routePoints != null && _routePoints!.isNotEmpty) {
      polylines.add(
        Polyline(
          points: _routePoints!,
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          strokeWidth: 4,
        ),
      );
    }

    if (_routePoints != null && _routeProgress < _routePoints!.length) {
      polylines.add(
        Polyline(
          points: _routePoints!.sublist(_routeProgress > 0 ? _routeProgress - 1 : 0),
          color: theme.colorScheme.secondary,
          strokeWidth: 5,
          borderColor: Colors.white,
          borderStrokeWidth: 2,
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _driverPosition ?? const LatLng(13.76, 121.06),
              initialZoom: 16,
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
              MarkerLayer(markers: markers),
              PolylineLayer(polylines: polylines),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_notificationMessage != null) ...[
                  _buildNotification(theme),
                  const SizedBox(height: 8),
                ],
                _buildStopsTracker(theme),
              ],
            ),
          ),
          if (_navigationInfo != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _buildNavCard(theme),
            ),
          Positioned(
            right: 16,
            bottom: 120,
            child: _buildMapControls(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'locate',
          onPressed: _centerOnDriver,
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

  Widget _buildNotification(ThemeData theme) {
    final isFinal = _notificationMessage == 'All deliveries completed';
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

  Widget _buildStopsTracker(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _stopsExpanded = !_stopsExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Row(
                children: [
                  Icon(
                    Icons.local_gas_station_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delivery Stops',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (_completedStops.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        '${_completedStops.length}/${_deliveryStops.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  AnimatedRotation(
                    turns: _stopsExpanded ? 0.0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_less,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _stopsExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _deliveryStops
                          .map((stop) => _buildStopRow(theme, stop))
                          .toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildStopRow(ThemeData theme, _DeliveryStop stop) {
    final stopIdx = _deliveryStops.indexOf(stop);
    final isCompleted = _completedStops.contains(stopIdx);
    final nextIdx = _deliveryStops.indexWhere(
      (s) => !_completedStops.contains(_deliveryStops.indexOf(s)),
    );
    final isCurrent = nextIdx == stopIdx;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted
                  ? theme.colorScheme.primaryContainer
                  : isCurrent
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? Icon(Icons.check,
                      size: 14,
                      color: theme.colorScheme.onPrimaryContainer)
                  : isCurrent
                      ? Icon(Icons.navigation_rounded,
                          size: 14, color: theme.colorScheme.onPrimary)
                      : Text(
                          '${stop.stopNumber}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              stop.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                color:
                    isCompleted ? theme.colorScheme.onSurfaceVariant : null,
                decoration:
                    isCompleted ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard(ThemeData theme) {
    final info = _navigationInfo!;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.navigation_rounded,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.instruction,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.formattedDetail,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryStop {
  const _DeliveryStop({
    required this.position,
    required this.name,
    required this.stopNumber,
    required this.totalStops,
  });

  final LatLng position;
  final String name;
  final int stopNumber;
  final int totalStops;
}

class _NavigationInfo {
  const _NavigationInfo({
    required this.instruction,
    required this.distanceKm,
    required this.etaMinutes,
    this.stopLabel,
  });

  final String instruction;
  final double distanceKm;
  final int etaMinutes;
  final String? stopLabel;

  String get formattedDetail {
    final parts = <String>[
      '${distanceKm.toStringAsFixed(1)} km',
      '$etaMinutes min',
    ];
    if (stopLabel != null) {
      parts.insert(0, stopLabel!);
    }
    return parts.join(' • ');
  }
}
