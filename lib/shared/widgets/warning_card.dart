import 'package:flutter/material.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

class WarningCard extends StatelessWidget {
  final String? message;
  final bool isActive;

  const WarningCard({super.key, this.message, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    if (message == null) {
      return Container(
        padding: const EdgeInsets.all(FleetSpacing.md),
        decoration: BoxDecoration(
          color: AppTheme.successGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(FleetRadius.sm),
          border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, size: 18, color: AppTheme.successGreen),
            const SizedBox(width: FleetSpacing.sm),
            Text(
              'No active warnings',
              style: TextStyle(
                color: AppTheme.successGreen,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final bgColor = isActive
        ? AppTheme.dangerRed.withValues(alpha: 0.08)
        : AppTheme.warningAmber.withValues(alpha: 0.08);
    final fgColor = isActive ? AppTheme.dangerRed : AppTheme.warningAmber;
    final icon = isActive ? Icons.warning_amber_rounded : Icons.info_outline;

    return Container(
      padding: const EdgeInsets.all(FleetSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(FleetRadius.sm),
        border: Border.all(color: fgColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fgColor),
          const SizedBox(width: FleetSpacing.sm),
          Expanded(
            child: Text(
              message!,
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
