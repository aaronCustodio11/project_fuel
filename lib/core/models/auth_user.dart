class AuthUser {
  const AuthUser({
    required this.userId,
    required this.firstName,
    required this.surName,
    required this.email,
    required this.role,
    required this.company,
    this.supplierId,
    this.latitude,
    this.longitude,
  });

  final int userId;
  final String firstName;
  final String surName;
  final String email;
  final String role;
  final String company;
  final int? supplierId;
  final double? latitude;
  final double? longitude;

  String get fullName => '$firstName $surName'.trim();
}
