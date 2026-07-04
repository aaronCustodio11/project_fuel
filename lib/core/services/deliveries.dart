export 'package:project_fuel/core/models/truck.dart';
import 'package:project_fuel/core/models/truck.dart';
import 'package:project_fuel/core/services/json_reader.dart';

class DeliveryService {
  final JsonReaderService? _jsonReader;
  static const _assetPath = 'assets/mock_data/vehicles.json';

  DeliveryService({JsonReaderService? jsonReader}) : _jsonReader = jsonReader;

  Future<List<TruckModel>> getAllTruckData() async {
    final rawList = await (_jsonReader?.readList(_assetPath) ??
        JsonReaderService.readListStatic(_assetPath));

    return rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => TruckModel.fromJson(item))
        .toList();
  }

  Future<List<DeliveryModel>> getDeliveriesForDriver(int driverId) async {
    final trucks = await getAllTruckData();

    for (final truck in trucks) {
      if (truck.driverId == driverId) {
        return truck.deliveries;
      }
    }

    return [];
  }

  Future<TruckModel?> getTruckForDriver(int driverId) async {
    final trucks = await getAllTruckData();

    for (final truck in trucks) {
      if (truck.driverId == driverId) {
        return truck;
      }
    }
    return null;
  }
}
