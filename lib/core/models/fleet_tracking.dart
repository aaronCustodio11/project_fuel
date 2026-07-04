import 'package:latlong2/latlong.dart';

enum TruckStatus { moving, idle, maintenance, offDuty }

enum StationType { gasStation, warehouse }

class FleetTruck {
  final String id;
  final String name;
  final String plateNumber;
  final LatLng position;
  final TruckStatus status;
  final String? driver;
  final double? speed;
  final double? fuelLevel;
  final String? lastUpdate;

  const FleetTruck({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.position,
    required this.status,
    this.driver,
    this.speed,
    this.fuelLevel,
    this.lastUpdate,
  });
}

class FleetStation {
  final String id;
  final String name;
  final LatLng position;
  final StationType type;
  final String? address;
  final double? fuelLevel;

  const FleetStation({
    required this.id,
    required this.name,
    required this.position,
    required this.type,
    this.address,
    this.fuelLevel,
  });
}
