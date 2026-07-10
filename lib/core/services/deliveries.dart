export 'package:project_fuel/core/models/truck.dart';
import 'package:project_fuel/core/models/truck.dart';
import 'package:project_fuel/core/services/json_reader.dart';

class DeliveryService {
  final JsonReaderService? _jsonReader;
  static const _vehiclesPath = 'assets/mock_data/vehicles.json';
  static const _deliveriesPath = 'assets/mock_data/deliveries.json';
  static const _stationsPath = 'assets/mock_data/stations.json';

  DeliveryService({JsonReaderService? jsonReader}) : _jsonReader = jsonReader;

  Future<List<dynamic>> _readJson(String path) async {
    return _jsonReader?.readList(path) ?? JsonReaderService.readListStatic(path);
  }

  Future<List<TruckModel>> getAllTruckData() async {
    final rawList = await _readJson(_vehiclesPath);
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => TruckModel.fromJson(item))
        .toList();
  }

  Future<List<DeliveryModel>> getAllDeliveries() async {
    final [rawDeliveries, rawStations] = await Future.wait([
      _readJson(_deliveriesPath),
      _readJson(_stationsPath),
    ]);

    final stationMap = <String, Map<String, dynamic>>{};
    for (final s in rawStations) {
      final station = s as Map<String, dynamic>;
      stationMap[station['stationId'] as String? ?? ''] = station;
    }

    return rawDeliveries.whereType<Map<String, dynamic>>().map((d) {
      final stationId = d['stationId'] as String? ?? '';
      final sourceStationId = d['sourceStation'] as String? ?? '';
      final station = stationMap[stationId];
      final sourceStation = stationMap[sourceStationId];

      return DeliveryModel(
        id: d['id'] as String? ?? '',
        truckId: d['truckId'] as String? ?? '',
        stationId: stationId,
        product: d['product'] as String? ?? '',
        quantity: d['quantity'] as int? ?? 0,
        unit: d['unit'] as String? ?? '',
        status: d['status'] as String? ?? '',
        scheduledDate: d['scheduledDate'] != null
            ? DateTime.tryParse(d['scheduledDate'] as String)
            : null,
        completedDate: d['completedDate'] != null
            ? DateTime.tryParse(d['completedDate'] as String)
            : null,
        sourceStationId: sourceStationId,
        notes: d['notes'] as String? ?? '',
        stationName: station?['name'] as String? ?? stationId,
        stationLat: (station?['lat'] as num? ?? 0.0).toDouble(),
        stationLng: (station?['lng'] as num? ?? 0.0).toDouble(),
        stationType: station?['type'] as String? ?? '',
        sourceStationName: sourceStation?['name'] as String? ?? sourceStationId,
        sourceStationLat: (sourceStation?['lat'] as num? ?? 0.0).toDouble(),
        sourceStationLng: (sourceStation?['lng'] as num? ?? 0.0).toDouble(),
        sourceStationType: sourceStation?['type'] as String? ?? '',
      );
    }).toList();
  }

  Future<List<DeliveryModel>> getDeliveriesForDriver(int driverId) async {
    final trucks = await getAllTruckData();
    final truck = trucks.where((t) => t.driverId == driverId).firstOrNull;
    if (truck == null) return [];

    final deliveries = await getAllDeliveries();
    return deliveries.where((d) => d.truckId == truck.truckId).toList();
  }

  Future<TruckModel?> getTruckForDriver(int driverId) async {
    final trucks = await getAllTruckData();
    return trucks.where((t) => t.driverId == driverId).firstOrNull;
  }
}
