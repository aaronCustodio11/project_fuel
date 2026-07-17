enum OrderStatus {
  pendingApproval,
  approved,
  rejected,
  accepted,
  inProgress,
  completed;

  String get label {
    switch (this) {
      case OrderStatus.pendingApproval:
        return 'Pending Approval';
      case OrderStatus.approved:
        return 'Approved';
      case OrderStatus.rejected:
        return 'Rejected';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.completed:
        return 'Completed';
    }
  }

  static OrderStatus fromString(String s) {
    return switch (s) {
      'approved' => OrderStatus.approved,
      'rejected' => OrderStatus.rejected,
      'accepted' => OrderStatus.accepted,
      'inProgress' => OrderStatus.inProgress,
      'completed' => OrderStatus.completed,
      _ => OrderStatus.pendingApproval,
    };
  }
}

class Order {
  final String orderId;
  final String depotId;
  final String stationId;
  final OrderStatus status;
  final int createdBy;
  final int? approvedBy;
  final int? acceptedBy;
  final String fuelType;
  final double quantity;
  final DateTime? scheduledDate;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? acceptedAt;
  final String? rejectionReason;

  const Order({
    required this.orderId,
    required this.depotId,
    required this.stationId,
    this.status = OrderStatus.pendingApproval,
    required this.createdBy,
    this.approvedBy,
    this.acceptedBy,
    required this.fuelType,
    required this.quantity,
    this.scheduledDate,
    required this.createdAt,
    this.approvedAt,
    this.acceptedAt,
    this.rejectionReason,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['orderId'] as String? ?? '',
      depotId: json['depotId'] as String? ?? '',
      stationId: json['stationId'] as String? ?? '',
      status: OrderStatus.fromString(json['status'] as String? ?? ''),
      createdBy: json['createdBy'] as int? ?? 0,
      approvedBy: json['approvedBy'] as int?,
      acceptedBy: json['acceptedBy'] as int?,
      fuelType: json['fuelType'] as String? ?? '',
      quantity: (json['quantity'] as num? ?? 0).toDouble(),
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.tryParse(json['scheduledDate'] as String)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'] as String)
          : null,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'] as String)
          : null,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'depotId': depotId,
        'stationId': stationId,
        'status': status.name,
        'createdBy': createdBy,
        'approvedBy': approvedBy,
        'acceptedBy': acceptedBy,
        'fuelType': fuelType,
        'quantity': quantity,
        'scheduledDate': scheduledDate?.toIso8601String().split('T')[0],
        'createdAt': createdAt.toIso8601String(),
        'approvedAt': approvedAt?.toIso8601String(),
        'acceptedAt': acceptedAt?.toIso8601String(),
        'rejectionReason': rejectionReason,
      };

  Order copyWith({
    String? orderId,
    String? depotId,
    String? stationId,
    OrderStatus? status,
    int? createdBy,
    int? approvedBy,
    int? acceptedBy,
    String? fuelType,
    double? quantity,
    DateTime? scheduledDate,
    DateTime? createdAt,
    DateTime? approvedAt,
    DateTime? acceptedAt,
    String? rejectionReason,
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      depotId: depotId ?? this.depotId,
      stationId: stationId ?? this.stationId,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
      acceptedBy: acceptedBy ?? this.acceptedBy,
      fuelType: fuelType ?? this.fuelType,
      quantity: quantity ?? this.quantity,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
