import 'package:project_fuel/core/services/json_reader.dart';

class AuthUser {
  const AuthUser({
    required this.userId,
    required this.firstName,
    required this.surName,
    required this.email,
    required this.role,
    required this.company,
  });

  final int userId;
  final String firstName;
  final String surName;
  final String email;
  final String role;
  final String company;

  String get fullName => '$firstName $surName'.trim();
}

class AuthenticationService {
  AuthenticationService({JsonReaderService? jsonReader}) : _jsonReader = jsonReader;

  final JsonReaderService? _jsonReader;

  Future<AuthUser?> login({required String email, required String password}) async {
    final users = await (_jsonReader?.readList('assets/mock_data/authentication.json') ??
        JsonReaderService.readListStatic('assets/mock_data/authentication.json'));

    for (final item in users) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final normalizedEmail = (item['email'] as String? ?? '').trim().toLowerCase();
      final normalizedPassword = item['password'] as String? ?? '';

      if (normalizedEmail == email.trim().toLowerCase() &&
          normalizedPassword == password) {
        return AuthUser(
          userId: item['userId'] as int,
          firstName: item['firstName'] as String? ?? '',
          surName: item['surName'] as String? ?? '',
          email: normalizedEmail,
          role: (item['role'] as String? ?? '').trim(),
          company: item['company'] as String? ?? '',
        );
      }
    }

    return null;
  }

  String getRouteForRole(String role) {
    switch (role.toLowerCase()) {
      case 'driver':
        return '/driver/home';
      case 'manager':
        return '/manager/home';
      case 'supplier':
        return '/supplier/home';
      default:
        return '/login';
    }
  }
}
