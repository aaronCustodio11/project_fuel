class TheftAlert {
  final String id;
  final String vehicleId;
  final String type;
  final String severity;
  final String description;
  final DateTime timestamp;
  final double lat;
  final double lng;
  final bool isResolved;
  final DateTime? resolvedAt;
  final int? resolvedBy;
  final int detectedBy;

  const TheftAlert({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.severity,
    required this.description,
    required this.timestamp,
    required this.lat,
    required this.lng,
    required this.isResolved,
    this.resolvedAt,
    this.resolvedBy,
    required this.detectedBy,
  });

  factory TheftAlert.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final resolvedAtStr = json['resolvedAt'] as String?;

    return TheftAlert(
      id: json['id'] as String? ?? '',
      vehicleId: json['vehicleId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      severity: json['severity'] as String? ?? '',
      description: json['description'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      lat: (location['lat'] as num? ?? 0.0).toDouble(),
      lng: (location['lng'] as num? ?? 0.0).toDouble(),
      isResolved: json['isResolved'] as bool? ?? false,
      resolvedAt: resolvedAtStr != null ? DateTime.tryParse(resolvedAtStr) : null,
      resolvedBy: json['resolvedBy'] as int?,
      detectedBy: json['detectedBy'] as int? ?? 0,
    );
  }
}
