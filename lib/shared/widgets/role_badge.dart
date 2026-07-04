import 'package:flutter/material.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({
    super.key,
    this.role,
    this.size = 46,
    this.tooltip,
    this.color,
    this.icon,
    this.onTap,
    this.borderWidth = 3,
    this.glowOpacity = 0.4,
  }) : assert(role != null || (color != null && icon != null),
            'Either role or both color and icon must be provided');

  final String? role;
  final double size;
  final String? tooltip;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;
  final double borderWidth;
  final double glowOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (role != null && (color == null || icon == null)) {
      final config = _resolveConfig(role!, theme);
      final resolvedColor = color ?? config.color;
      final resolvedIcon = icon ?? config.icon;

      return _buildBadge(context, resolvedColor, resolvedIcon);
    }

    return _buildBadge(context, color!, icon!);
  }

  Widget _buildBadge(BuildContext context, Color badgeColor, IconData badgeIcon) {
    final iconSize = size > 46 ? 22.0 : 20.0;

    final badge = Material(
      color: Colors.transparent,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: badgeColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: badgeColor.withValues(alpha: glowOpacity),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(color: Colors.white, width: borderWidth),
        ),
        child: Icon(badgeIcon, color: Colors.white, size: iconSize),
      ),
    );

    Widget result = badge;
    if (onTap != null) {
      result = GestureDetector(onTap: onTap, child: badge);
    }
    if (tooltip != null) {
      result = Tooltip(message: tooltip!, child: result);
    }

    return result;
  }
}

class _RoleBadgeConfig {
  const _RoleBadgeConfig({required this.color, required this.icon});

  final Color color;
  final IconData icon;
}

_RoleBadgeConfig _resolveConfig(String role, ThemeData theme) {
  switch (role) {
    case 'station':
      return const _RoleBadgeConfig(
        color: Colors.orangeAccent,
        icon: Icons.local_gas_station_rounded,
      );
    case 'driver':
    default:
      return _RoleBadgeConfig(
        color: theme.colorScheme.primary,
        icon: Icons.local_shipping_rounded,
      );
  }
}
