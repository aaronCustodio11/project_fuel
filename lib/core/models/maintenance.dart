enum MaintenanceStatus {
  scheduled('Scheduled'),
  inProgress('In Progress'),
  completed('Completed'),
  cancelled('Cancelled');

  final String label;
  const MaintenanceStatus(this.label);

  static MaintenanceStatus fromString(String s) {
    return MaintenanceStatus.values.firstWhere((e) => e.name == s);
  }
}

enum MaintenancePriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  critical('Critical');

  final String label;
  const MaintenancePriority(this.label);

  static MaintenancePriority fromString(String s) {
    return MaintenancePriority.values.firstWhere((e) => e.name == s);
  }
}

class MaintenanceNote {
  final String id;
  final String author;
  final String note;
  final DateTime timestamp;

  const MaintenanceNote({
    required this.id,
    required this.author,
    required this.note,
    required this.timestamp,
  });

  factory MaintenanceNote.fromJson(Map<String, dynamic> json) {
    return MaintenanceNote(
      id: json['id'] as String,
      author: json['author'] as String,
      note: json['note'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'author': author,
    'note': note,
    'timestamp': timestamp.toIso8601String(),
  };
}

class MaintenanceRecord {
  final String id;
  final String vehicleId;
  final String vehicleName;
  final String type;
  final String description;
  final MaintenanceStatus status;
  final MaintenancePriority priority;
  final DateTime? scheduledDate;
  final DateTime? completedDate;
  final double cost;
  final List<MaintenanceNote> notes;
  final int? assignedToId;
  final DateTime createdAt;

  const MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.vehicleName,
    required this.type,
    required this.description,
    required this.status,
    required this.priority,
    this.scheduledDate,
    this.completedDate,
    this.cost = 0,
    this.notes = const [],
    this.assignedToId,
    required this.createdAt,
  });

  MaintenanceRecord copyWith({
    MaintenanceStatus? status,
    double? cost,
    DateTime? completedDate,
    List<MaintenanceNote>? notes,
  }) {
    return MaintenanceRecord(
      id: id,
      vehicleId: vehicleId,
      vehicleName: vehicleName,
      type: type,
      description: description,
      status: status ?? this.status,
      priority: priority,
      scheduledDate: scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
      assignedToId: assignedToId,
      createdAt: createdAt,
    );
  }

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      vehicleName: json['vehicleName'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      status: MaintenanceStatus.fromString(json['status'] as String),
      priority: MaintenancePriority.fromString(json['priority'] as String),
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'] as String)
          : null,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      cost: (json['cost'] as num).toDouble(),
      notes: (json['notes'] as List<dynamic>?)
              ?.map((e) => MaintenanceNote.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      assignedToId: json['assignedToId'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
