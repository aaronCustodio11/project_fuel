class TruckModel {
  final String truckId;
  final String plateNumber;
  final int? driverId;
  final int supplierId;
  final String status;
  final int speedKph;
  final int heading;
  final double latitude;
  final double longitude;

  const TruckModel({
    required this.truckId,
    required this.plateNumber,
    this.driverId,
    this.supplierId = 0,
    this.status = '',
    this.speedKph = 0,
    this.heading = 0,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  factory TruckModel.fromJson(Map<String, dynamic> json) {
    final location = json['currentLocation'] as Map<String, dynamic>? ?? {};

    return TruckModel(
      truckId: json['truckId'] as String? ?? '',
      plateNumber: json['plateNumber'] as String? ?? '',
      driverId: json['driverId'] as int?,
      supplierId: json['supplierId'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      speedKph: json['speedKph'] as int? ?? 0,
      heading: json['heading'] as int? ?? 0,
      latitude: (location['latitude'] as num? ?? 0.0).toDouble(),
      longitude: (location['longitude'] as num? ?? 0.0).toDouble(),
    );
  }
}

class DeliveryModel {
  final String id;
  final String truckId;
  final String stationId;
  final String product;
  final int quantity;
  final String unit;
  final String status;
  final DateTime? scheduledDate;
  final DateTime? completedDate;
  final String sourceStationId;
  final String notes;

  final String stationName;
  final double stationLat;
  final double stationLng;
  final String sourceStationName;

  const DeliveryModel({
    required this.id,
    required this.truckId,
    required this.stationId,
    required this.product,
    required this.quantity,
    required this.unit,
    required this.status,
    this.scheduledDate,
    this.completedDate,
    this.sourceStationId = '',
    this.notes = '',
    this.stationName = '',
    this.stationLat = 0.0,
    this.stationLng = 0.0,
    this.sourceStationName = '',
  });
}
