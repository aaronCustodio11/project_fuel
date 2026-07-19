import 'package:flutter/material.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

class MapLegend extends StatefulWidget {
  const MapLegend({super.key});

  @override
  State<MapLegend> createState() => _MapLegendState();
}

class _MapLegendState extends State<MapLegend> {
  bool _isExpanded = false;

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final entries = [
      _LegendEntry(color: AppTheme.truckMoving, label: 'Moving'),
      _LegendEntry(color: AppTheme.warningAmber, label: 'Idle'),
      _LegendEntry(color: AppTheme.dangerRed, label: 'Maintenance'),
      _LegendEntry(color: AppTheme.neutralGray500, label: 'Off Duty'),
      _LegendEntry(color: AppTheme.stationGas, label: 'Gas Station'),
      _LegendEntry(color: AppTheme.stationDepot, label: 'Depot'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FloatingActionButton.small(
          heroTag: 'legend_toggle',
          onPressed: _toggle,
          backgroundColor: Theme.of(context).colorScheme.surface,
          tooltip: _isExpanded ? 'Hide legend' : 'Show legend',
          child: Icon(
            _isExpanded ? Icons.close : Icons.help_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        if (_isExpanded)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: e.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(e.label, style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    )),
                  ],
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }
}

class _LegendEntry {
  final Color color;
  final String label;
  const _LegendEntry({required this.color, required this.label});
}
