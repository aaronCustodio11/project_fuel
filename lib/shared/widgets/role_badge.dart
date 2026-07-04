import 'package:flutter/material.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({
    super.key,
    required this.role,
    this.size = 46,
    this.tooltip,
  });

  final String role;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _resolveConfig(role, theme);

    final iconSize = size > 46 ? 22.0 : 20.0;

    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: config.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Icon(config.icon, color: Colors.white, size: iconSize),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: badge);
    }

    return badge;
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
