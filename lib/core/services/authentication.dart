import 'package:project_fuel/core/services/json_reader.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const _storageKey = 'auth_user_email';

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
        final authUser = AuthUser(
          userId: item['userId'] as int,
          firstName: item['firstName'] as String? ?? '',
          surName: item['surName'] as String? ?? '',
          email: normalizedEmail,
          role: (item['role'] as String? ?? '').trim(),
          company: item['company'] as String? ?? '',
        );

        await persistUser(authUser);
        return authUser;
      }
    }

    return null;
  }

  Future<void> persistUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, user.email);
  }

  Future<AuthUser?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_storageKey);

    if (savedEmail == null || savedEmail.isEmpty) {
      return null;
    }

    final users = await (_jsonReader?.readList('assets/mock_data/authentication.json') ??
        JsonReaderService.readListStatic('assets/mock_data/authentication.json'));

    for (final item in users) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final normalizedEmail = (item['email'] as String? ?? '').trim().toLowerCase();
      if (normalizedEmail == savedEmail.toLowerCase()) {
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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
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
