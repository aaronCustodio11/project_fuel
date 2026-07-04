import 'package:flutter/material.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FleetRadius.md),
      ),
      title: const Text('Log out'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.dangerRed,
            foregroundColor: Colors.white,
          ),
          child: const Text('Log out'),
        ),
      ],
    ),
  );

  return result ?? false;
}
