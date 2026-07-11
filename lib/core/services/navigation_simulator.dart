import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class NavigationStop {
  final String id;
  final String name;
  final LatLng position;

  const NavigationStop({
    required this.id,
    required this.name,
    required this.position,
  });
}

class NavigationState {
  final LatLng currentPosition;
  final int routeIndex;
  final Set<int> completedStopIndices;
  final double remainingDistanceKm;
  final int etaMinutes;
  final bool isComplete;
  final String? notification;
  final int? lastCompletedStopIndex;

  const NavigationState({
    required this.currentPosition,
    required this.routeIndex,
    required this.completedStopIndices,
    required this.remainingDistanceKm,
    required this.etaMinutes,
    this.isComplete = false,
    this.notification,
    this.lastCompletedStopIndex,
  });
}

class NavigationSimulator {
  final List<LatLng> _route;
  final List<NavigationStop> _stops;
  final double _speedKph;
  final int _tickMs;
  final double _arrivalThresholdKm;

  final ValueNotifier<NavigationState> state;

  int _routeIndex = 0;
  final Set<int> _completedStops = {};
  Timer? _timer;
  bool _isPaused = false;
  String? _currentNotification;
  int? _lastCompletedIndex;

  double get _metersPerTick => (_speedKph * 1000 / 3600) * (_tickMs / 1000);

  NavigationSimulator({
    required List<LatLng> route,
    required List<NavigationStop> stops,
    double speedKph = 45,
    int tickMs = 1000,
    double arrivalThresholdKm = 0.05,
  })  : _route = List.from(route),
        _stops = List.unmodifiable(stops),
        _speedKph = speedKph > 0 ? speedKph : 45,
        _tickMs = tickMs,
        _arrivalThresholdKm = arrivalThresholdKm,
        state = ValueNotifier<NavigationState>(
          NavigationState(
            currentPosition: route.isNotEmpty ? route.first : const LatLng(0, 0),
            routeIndex: 0,
            completedStopIndices: {},
            remainingDistanceKm: _calculateRouteDistance(route, 0),
            etaMinutes: _calculateRouteDistance(route, 0) > 0
                ? (_calculateRouteDistance(route, 0) / speedKph * 60).round().clamp(1, 999)
                : 0,
          ),
        );

  void start() {
    if (_route.length < 2) return;
    _routeIndex = 0;
    _completedStops.clear();
    _isPaused = false;
    _timer = Timer.periodic(Duration(milliseconds: _tickMs), _tick);
  }

  void pause() {
    _isPaused = true;
  }

  void resume() {
    if (_isPaused && _timer != null) {
      _isPaused = false;
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    state.dispose();
  }

  void _tick(Timer timer) {
    if (_isPaused) return;

    if (_routeIndex >= _route.length - 1) {
      _complete();
      return;
    }

    final current = _route[_routeIndex];
    final next = _route[_routeIndex + 1];
    final segmentDist = _distanceBetween(current, next);
    final stepDist = _metersPerTick / 1000;

    if (stepDist >= segmentDist && _routeIndex < _route.length - 1) {
      _routeIndex++;
      _advance(stepDist);
    } else {
      final fraction = (segmentDist > 0) ? stepDist / segmentDist : 1.0;
      final lat = current.latitude + (next.latitude - current.latitude) * fraction;
      final lng = current.longitude + (next.longitude - current.longitude) * fraction;
      _route[_routeIndex] = LatLng(lat, lng);
      _advance(stepDist);
    }
  }

  void _advance(double stepKm) {
    final pos = _route[_routeIndex];

    for (var i = 0; i < _stops.length; i++) {
      if (!_completedStops.contains(i)) {
        final dist = _distanceBetween(pos, _stops[i].position);
        if (dist < _arrivalThresholdKm) {
          _completedStops.add(i);
          _lastCompletedIndex = i;
          _setNotification('Arrived at ${_stops[i].name}');
          Future.delayed(const Duration(seconds: 3), () {
            if (_currentNotification == 'Arrived at ${_stops[i].name}') {
              _setNotification(null);
            }
          });
        }
      }
    }

    _publishState();
  }

  void _complete() {
    _timer?.cancel();
    _timer = null;
    state.value = NavigationState(
      currentPosition: _route.last,
      routeIndex: _route.length - 1,
      completedStopIndices: Set.from(_completedStops),
      remainingDistanceKm: 0,
      etaMinutes: 0,
      isComplete: true,
      notification: 'All stops completed',
      lastCompletedStopIndex: _lastCompletedIndex,
    );
  }

  void _setNotification(String? msg) {
    _currentNotification = msg;
    _publishState();
  }

  void _publishState() {
    final pos = _route[_routeIndex];
    final remaining = _route.sublist(_routeIndex);
    final remainingKm = _calculateRouteDistance(remaining, 0);

    state.value = NavigationState(
      currentPosition: pos,
      routeIndex: _routeIndex,
      completedStopIndices: Set.from(_completedStops),
      remainingDistanceKm: remainingKm,
      etaMinutes: remainingKm > 0
          ? (remainingKm / _speedKph * 60).round().clamp(1, 999)
          : 0,
      isComplete: false,
      notification: _currentNotification,
      lastCompletedStopIndex: _lastCompletedIndex,
    );
  }

  static double _distanceBetween(LatLng a, LatLng b) {
    const earthRadius = 6371.0;
    final lat1 = a.latitude * (math.pi / 180);
    final lat2 = b.latitude * (math.pi / 180);
    final deltaLat = (b.latitude - a.latitude) * (math.pi / 180);
    final deltaLng = (b.longitude - a.longitude) * (math.pi / 180);
    final x = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
  }

  static double _calculateRouteDistance(List<LatLng> route, int startIndex) {
    double total = 0;
    for (var i = startIndex; i < route.length - 1; i++) {
      total += _distanceBetween(route[i], route[i + 1]);
    }
    return total;
  }
}
