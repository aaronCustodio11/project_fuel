import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OSRMRoutingService {
  static const _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  Future<RouteResult?> getRoute({
    required List<LatLng> waypoints,
  }) async {
    if (waypoints.length < 2) return null;

    final coords = waypoints
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');

    final url = Uri.parse(
      '$_baseUrl/$coords'
      '?overview=full&geometries=geojson&steps=true&continue_straight=false',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes[0] as Map<String, dynamic>;

      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;

      final polyline = coordinates.map((c) {
        final coord = c as List<dynamic>;
        return LatLng(
          (coord[1] as num).toDouble(),
          (coord[0] as num).toDouble(),
        );
      }).toList();

      final legs = route['legs'] as List<dynamic>? ?? [];
      final allSteps = <TurnStep>[];

      for (final leg in legs) {
        final steps = (leg as Map<String, dynamic>)['steps'] as List<dynamic>? ?? [];
        for (final step in steps) {
          final s = step as Map<String, dynamic>;
          final maneuver = s['maneuver'] as Map<String, dynamic>?;
          final type = maneuver?['type'] as String? ?? '';
          final modifier = maneuver?['modifier'] as String? ?? '';

          if (type == 'depart' || type == 'arrive') continue;

          allSteps.add(TurnStep(
            instruction: s['instruction'] as String? ?? '',
            modifier: modifier,
            type: type,
            distance: (s['distance'] as num? ?? 0).toDouble(),
            streetName: s['name'] as String? ?? '',
          ));
        }
      }

      return RouteResult(polyline: polyline, steps: allSteps);
    } catch (_) {
      return null;
    }
  }
}

class RouteResult {
  final List<LatLng> polyline;
  final List<TurnStep> steps;

  const RouteResult({required this.polyline, required this.steps});
}

class TurnStep {
  final String instruction;
  final String modifier;
  final String type;
  final double distance;
  final String streetName;

  const TurnStep({
    required this.instruction,
    required this.modifier,
    required this.type,
    required this.distance,
    required this.streetName,
  });
}
