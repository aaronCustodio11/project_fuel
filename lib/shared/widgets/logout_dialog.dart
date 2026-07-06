import 'package:flutter/material.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
  final theme = Theme.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FleetRadius.md),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.dangerRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.logout_rounded,
              size: 28,
              color: AppTheme.dangerRed,
            ),
          ),
          Text('Log out', textAlign: TextAlign.center),
        ],
      ),
      content: Text(
        'Are you sure you want to log out? You will need to sign in again to access your account.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.dangerRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Log out'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  return result ?? false;
}
