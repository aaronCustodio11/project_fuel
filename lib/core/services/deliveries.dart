import 'package:project_fuel/core/services/json_reader.dart';

class TruckModel {
  final String truckId;
  final String plateNumber;
  final int driverId;
  final int supplierId;
  final String status;
  final int speedKph;
  final int heading;
  final double latitude;
  final double longitude;
  final List<DeliveryModel> deliveries;

  const TruckModel({
    required this.truckId,
    required this.plateNumber,
    required this.driverId,
    required this.supplierId,
    required this.status,
    required this.speedKph,
    required this.heading,
    required this.latitude,
    required this.longitude,
    required this.deliveries,
  });

  factory TruckModel.fromJson(Map<String, dynamic> json) {
    final location = json['currentLocation'] as Map<String, dynamic>? ?? {};
    final deliveryList = json['deliveries'] as List<dynamic>? ?? [];

    return TruckModel(
      truckId: json['truckId'] as String? ?? '',
      plateNumber: json['plateNumber'] as String? ?? '',
      driverId: json['driverId'] as int? ?? 0,
      supplierId: json['supplierId'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      speedKph: json['speedKph'] as int? ?? 0,
      heading: json['heading'] as int? ?? 0,
      latitude: (location['latitude'] as num? ?? 0.0).toDouble(),
      longitude: (location['longitude'] as num? ?? 0.0).toDouble(),
      deliveries: deliveryList
          .map((d) => DeliveryModel.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DeliveryModel {
  final String deliveryId;
  final int managerId;
  final String gasStation;
  final double destLatitude;
  final double destLongitude;
  final String fuelType;
  final int volumeLiters;
  final String status;
  final DateTime? eta;

  const DeliveryModel({
    required this.deliveryId,
    required this.managerId,
    required this.gasStation,
    required this.destLatitude,
    required this.destLongitude,
    required this.fuelType,
    required this.volumeLiters,
    required this.status,
    this.eta,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    final destination = json['destination'] as Map<String, dynamic>? ?? {};
    final etaStr = json['eta'] as String?;

    return DeliveryModel(
      deliveryId: json['deliveryId'] as String? ?? '',
      managerId: json['managerId'] as int? ?? 0,
      gasStation: json['gasStation'] as String? ?? '',
      destLatitude: (destination['latitude'] as num? ?? 0.0).toDouble(),
      destLongitude: (destination['longitude'] as num? ?? 0.0).toDouble(),
      fuelType: json['fuelType'] as String? ?? '',
      volumeLiters: json['volumeLiters'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      eta: etaStr != null ? DateTime.tryParse(etaStr) : null,
    );
  }
}

class DeliveryService {
  final JsonReaderService? _jsonReader;
  static const _assetPath = 'assets/mock_data/truck_navigation.json'; // Ensure this matches your file path

  DeliveryService({JsonReaderService? jsonReader}) : _jsonReader = jsonReader;

  /// Retrieves all truck profiles from the data layer
  Future<List<TruckModel>> getAllTruckData() async {
    final rawList = await (_jsonReader?.readList(_assetPath) ??
        JsonReaderService.readListStatic(_assetPath));

    return rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => TruckModel.fromJson(item))
        .toList();
  }

  /// Retrieves all delivery assignments for a specific driver ID
  Future<List<DeliveryModel>> getDeliveriesForDriver(int driverId) async {
    final trucks = await getAllTruckData();
    
    for (final truck in trucks) {
      if (truck.driverId == driverId) {
        return truck.deliveries;
      }
    }
    
    return []; // Return empty if no assigned truck matches the driverId
  }

  /// Retrieves the active/associated truck configuration details for a driver
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