import 'package:latlong2/latlong.dart';

enum TruckStatus { moving, idle, maintenance, offDuty }

enum StationType { gasStation, warehouse }

class FleetTruck {
  final String id;
  final String name;
  final String plateNumber;
  final LatLng position;
  final TruckStatus status;
  final int? driverId;
  final double? speed;
  final double? fuelLevel;
  final String? lastUpdate;

  const FleetTruck({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.position,
    required this.status,
    this.driverId,
    this.speed,
    this.fuelLevel,
    this.lastUpdate,
  });

  factory FleetTruck.fromVehicleJson(Map<String, dynamic> json) {
    final location = json['currentLocation'] as Map<String, dynamic>? ?? {};
    final status = switch (json['status'] as String? ?? '') {
      'En Route' || 'Delivering' => TruckStatus.moving,
      'Idle' => TruckStatus.idle,
      'Completed' => TruckStatus.offDuty,
      _ => TruckStatus.maintenance,
    };

    return FleetTruck(
      id: json['truckId'] as String? ?? '',
      name: 'Truck #${json['truckId'] as String? ?? ''}',
      plateNumber: json['plateNumber'] as String? ?? '',
      position: LatLng(
        (location['latitude'] as num? ?? 0.0).toDouble(),
        (location['longitude'] as num? ?? 0.0).toDouble(),
      ),
      status: status,
      driverId: json['driverId'] as int?,
      speed: (json['speedKph'] as num?)?.toDouble(),
      fuelLevel: (json['fuelLevel'] as num?)?.toDouble(),
      lastUpdate: null,
    );
  }
}

class FleetStation {
  final String id;
  final String name;
  final LatLng position;
  final StationType type;
  final String? address;
  final double? fuelLevel;
  final int? managerId;
  final int? supplierId;

  const FleetStation({
    required this.id,
    required this.name,
    required this.position,
    required this.type,
    this.address,
    this.fuelLevel,
    this.managerId,
    this.supplierId,
  });

  factory FleetStation.fromJson(Map<String, dynamic> json) {
    return FleetStation(
      id: json['stationId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      position: LatLng(
        (json['lat'] as num? ?? 0.0).toDouble(),
        (json['lng'] as num? ?? 0.0).toDouble(),
      ),
      type: switch (json['type'] as String? ?? '') {
        'gasStation' => StationType.gasStation,
        _ => StationType.warehouse,
      },
      address: json['address'] as String?,
      fuelLevel: json['currentStock'] != null && json['capacity'] != null
          ? ((json['currentStock'] as num).toDouble() /
              (json['capacity'] as num).toDouble())
              .clamp(0.0, 1.0)
          : null,
      managerId: json['managerId'] as int?,
      supplierId: json['supplierId'] as int?,
    );
  }
}
