import 'package:chartify/chartify.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project_fuel/core/services/json_reader.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

enum TheftAlertType { fuelTheft, unauthorizedAccess, gpsTampering, routeDeviation }

enum TheftAlertStatus { newAlert, investigating, resolved, dismissed }

enum TheftAlertSeverity { critical, high, medium, low }

class TheftAlert {
  final String id;
  final String vehicleName;
  final String plateNumber;
  final TheftAlertType type;
  final TheftAlertSeverity severity;
  final TheftAlertStatus status;
  final DateTime timestamp;
  final String location;
  final String description;
  final String? resolvedBy;
  final DateTime? resolvedAt;

  const TheftAlert({
    required this.id,
    required this.vehicleName,
    required this.plateNumber,
    required this.type,
    required this.severity,
    required this.status,
    required this.timestamp,
    required this.location,
    required this.description,
    this.resolvedBy,
    this.resolvedAt,
  });
}

class SupervisorTheftDetection extends StatefulWidget {
  const SupervisorTheftDetection({super.key});

  @override
  State<SupervisorTheftDetection> createState() => _SupervisorTheftDetectionState();
}

class _SupervisorTheftDetectionState extends State<SupervisorTheftDetection> {
  List<TheftAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final results = await Future.wait([
      JsonReaderService.readListStatic('assets/mock_data/theft_alerts.json'),
      JsonReaderService.readListStatic('assets/mock_data/vehicles.json'),
      JsonReaderService.readListStatic('assets/mock_data/authentication.json'),
    ]);

    final rawAlerts = results[0];
    final vehicles = results[1];
    final users = results[2];

    final vehicleMap = <String, Map<String, dynamic>>{};
    for (final v in vehicles) {
      final vm = v as Map<String, dynamic>;
      vehicleMap[vm['truckId'] as String? ?? ''] = vm;
    }

    final userNameMap = <int, String>{};
    for (final u in users) {
      final id = u['userId'] as int?;
      if (id != null) {
        userNameMap[id] = '${u['firstName'] ?? ''} ${u['surName'] ?? ''}'.trim();
      }
    }

    final alerts = rawAlerts.whereType<Map<String, dynamic>>().map((a) {
      final vehicleId = a['vehicleId'] as String? ?? '';
      final vehicle = vehicleMap[vehicleId];
      final severityStr = a['severity'] as String? ?? 'medium';
      final typeStr = a['type'] as String? ?? 'fuelTheft';
      final isResolved = a['isResolved'] as bool? ?? false;

      TheftAlertSeverity severity;
      switch (severityStr) {
        case 'critical':
          severity = TheftAlertSeverity.critical;
        case 'high':
          severity = TheftAlertSeverity.high;
        case 'medium':
          severity = TheftAlertSeverity.medium;
        default:
          severity = TheftAlertSeverity.low;
      }

      TheftAlertType type;
      switch (typeStr) {
        case 'fuelTheft':
          type = TheftAlertType.fuelTheft;
        case 'unauthorizedAccess':
          type = TheftAlertType.unauthorizedAccess;
        case 'gpsTampering':
          type = TheftAlertType.gpsTampering;
        default:
          type = TheftAlertType.routeDeviation;
      }

      TheftAlertStatus status;
      if (isResolved) {
        if (a['resolvedBy'] != null) {
          status = TheftAlertStatus.resolved;
        } else {
          status = TheftAlertStatus.dismissed;
        }
      } else {
        status = TheftAlertStatus.newAlert;
      }

      final resolvedById = a['resolvedBy'] as int?;
      return TheftAlert(
        id: a['id'] as String? ?? '',
        vehicleName: vehicle?['truckId'] != null
            ? 'Truck #${vehicle!['truckId']}'
            : vehicleId,
        plateNumber: vehicle?['plateNumber'] as String? ?? '',
        type: type,
        severity: severity,
        status: status,
        timestamp: DateTime.parse(a['timestamp'] as String),
        location: '${a['location']?['lat'] ?? ''}, ${a['location']?['lng'] ?? ''}',
        description: a['description'] as String? ?? '',
        resolvedBy: resolvedById != null ? userNameMap[resolvedById] : null,
        resolvedAt: a['resolvedAt'] != null
            ? DateTime.tryParse(a['resolvedAt'] as String)
            : null,
      );
    }).toList();

    if (mounted) {
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    }
  }

  String _typeLabel(TheftAlertType t) => switch (t) {
    TheftAlertType.fuelTheft => 'Fuel Theft',
    TheftAlertType.unauthorizedAccess => 'Unauthorized Access',
    TheftAlertType.gpsTampering => 'GPS Tampering',
    TheftAlertType.routeDeviation => 'Route Deviation',
  };

  IconData _typeIcon(TheftAlertType t) => switch (t) {
    TheftAlertType.fuelTheft => Icons.local_gas_station_outlined,
    TheftAlertType.unauthorizedAccess => Icons.lock_open,
    TheftAlertType.gpsTampering => Icons.gps_fixed,
    TheftAlertType.routeDeviation => Icons.alt_route,
  };

  Color _typeColor(TheftAlertType t) => switch (t) {
    TheftAlertType.fuelTheft => AppTheme.warningAmber,
    TheftAlertType.unauthorizedAccess => AppTheme.dangerRed,
    TheftAlertType.gpsTampering => AppTheme.accentBlue,
    TheftAlertType.routeDeviation => AppTheme.brandBlue,
  };

  Color _severityColor(TheftAlertSeverity s) => switch (s) {
    TheftAlertSeverity.critical => AppTheme.dangerRed,
    TheftAlertSeverity.high => AppTheme.warningAmber,
    TheftAlertSeverity.medium => AppTheme.accentBlue,
    TheftAlertSeverity.low => AppTheme.neutralGray500,
  };

  Color _statusColor(TheftAlertStatus s) => switch (s) {
    TheftAlertStatus.newAlert => AppTheme.dangerRed,
    TheftAlertStatus.investigating => AppTheme.warningAmber,
    TheftAlertStatus.resolved => AppTheme.successGreen,
    TheftAlertStatus.dismissed => AppTheme.neutralGray500,
  };

  String _statusLabel(TheftAlertStatus s) => switch (s) {
    TheftAlertStatus.newAlert => 'New',
    TheftAlertStatus.investigating => 'Investigating',
    TheftAlertStatus.resolved => 'Resolved',
    TheftAlertStatus.dismissed => 'Dismissed',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: SafeArea(
        child: _isLoading
            ? Center(child: LoadingAnimationWidget.staggeredDotsWave(color: scheme.primary, size: 50))
            : _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final total = _alerts.length;
    final critical = _alerts.where((a) => a.severity == TheftAlertSeverity.critical && a.status != TheftAlertStatus.resolved && a.status != TheftAlertStatus.dismissed).length;
    final investigating = _alerts.where((a) => a.status == TheftAlertStatus.investigating).length;
    final resolved = _alerts.where((a) => a.status == TheftAlertStatus.resolved || a.status == TheftAlertStatus.dismissed).length;

    final activeAlerts = _alerts.where((a) => a.status != TheftAlertStatus.resolved && a.status != TheftAlertStatus.dismissed).toList();
    final archivedAlerts = _alerts.where((a) => a.status == TheftAlertStatus.resolved || a.status == TheftAlertStatus.dismissed).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(FleetSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Theft Detection', style: theme.textTheme.headlineLarge),
          const SizedBox(height: FleetSpacing.md),
          Row(
            children: [
              Expanded(child: _KpiCard(
                label: 'Total Alerts', value: '$total',
                subtitle: 'All time', icon: Icons.warning_amber_rounded,
                accentColor: scheme.primary,
              )),
              const SizedBox(width: FleetSpacing.md),
              Expanded(child: _KpiCard(
                label: 'Critical', value: '$critical',
                subtitle: 'Needs attention', icon: Icons.report_problem,
                accentColor: AppTheme.dangerRed,
              )),
              const SizedBox(width: FleetSpacing.md),
              Expanded(child: _KpiCard(
                label: 'Investigating', value: '$investigating',
                subtitle: 'In progress', icon: Icons.search,
                accentColor: AppTheme.warningAmber,
              )),
              const SizedBox(width: FleetSpacing.md),
              Expanded(child: _KpiCard(
                label: 'Resolved', value: '$resolved',
                subtitle: 'Closed', icon: Icons.check_circle_outline,
                accentColor: AppTheme.successGreen,
              )),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          SizedBox(
            height: 300,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _ChartCard(
                    title: 'Alerts by Type',
                    subtitle: '$total total alerts',
                    child: _buildTypeChart(),
                  ),
                ),
                const SizedBox(width: FleetSpacing.md),
                Expanded(
                  flex: 2,
                  child: _ChartCard(
                    title: 'Severity Distribution',
                    subtitle: 'Current breakdown',
                    child: _buildSeverityChart(theme),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FleetSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Alerts', style: theme.textTheme.titleLarge),
                    const SizedBox(height: FleetSpacing.md),
                    activeAlerts.isEmpty
                        ? _buildEmptyList(context, 'No active alerts.')
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activeAlerts.length,
                            separatorBuilder: (_, _) => const SizedBox(height: FleetSpacing.md),
                            itemBuilder: (_, i) => _AlertCard(
                                  alert: activeAlerts[i],
                                  typeLabel: _typeLabel,
                                  typeIcon: _typeIcon,
                                  typeColor: _typeColor,
                                  severityColor: _severityColor,
                                  statusColor: _statusColor,
                                  statusLabel: _statusLabel,
                                  onUpdateStatus: _updateAlertStatus,
                                ),
                              ),
                    ],
                  ),
                ),
                const SizedBox(width: FleetSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resolved & Dismissed', style: theme.textTheme.titleLarge),
                      const SizedBox(height: FleetSpacing.md),
                      archivedAlerts.isEmpty
                          ? _buildEmptyList(context, 'No resolved alerts.')
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: archivedAlerts.length,
                              separatorBuilder: (_, _) => const SizedBox(height: FleetSpacing.md),
                              itemBuilder: (_, i) => _AlertCard(
                                alert: archivedAlerts[i],
                                  typeLabel: _typeLabel,
                                  typeIcon: _typeIcon,
                                  typeColor: _typeColor,
                                  severityColor: _severityColor,
                                  statusColor: _statusColor,
                                  statusLabel: _statusLabel,
                                  onUpdateStatus: _updateAlertStatus,
                                ),
                              ),
                    ],
                  ),
                ),
              ],
            ),
          ],
      ),
    );
  }

  Widget _buildEmptyList(BuildContext context, String message) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(FleetSpacing.xl),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(FleetRadius.md),
        border: Border.all(color: scheme.outline),
      ),
      child: Text(message, style: theme.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      )),
    );
  }

  Widget _buildTypeChart() {
    final counts = <TheftAlertType, int>{};
    for (final a in _alerts) {
      counts[a.type] = (counts[a.type] ?? 0) + 1;
    }
    final types = TheftAlertType.values;
    final values = types.map((t) => (counts[t] ?? 0).toDouble()).toList();
    final labels = types.map(_typeLabel).toList();

    return RepaintBoundary(
      child: ChartTheme(
        data: ChartTheme.of(context).copyWith(
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        child: BarChart(
          data: BarChartData(
            series: [
              BarSeries.fromValues<double>(
                name: 'Alerts',
                values: values,
                color: const Color(0xFF6366F1),
                gradient: LinearGradient(
                  colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
            xAxis: BarXAxisConfig(categories: labels),
            yAxis: const BarYAxisConfig(min: 0, tickCount: 4),
            grouping: BarGrouping.grouped,
            direction: BarDirection.vertical,
          ),
          tooltip: const TooltipConfig(enabled: true),
          animation: const ChartAnimation.none(),
        ),
      ),
    );
  }

  Widget _buildSeverityChart(ThemeData theme) {
    final counts = <TheftAlertSeverity, int>{};
    for (final a in _alerts) {
      counts[a.severity] = (counts[a.severity] ?? 0) + 1;
    }
    final severities = TheftAlertSeverity.values;

    return RepaintBoundary(
      child: PieChart(
        data: PieChartData(
          sections: severities.where((s) => (counts[s] ?? 0) > 0).map((s) {
            return PieSection(
              value: (counts[s] ?? 0).toDouble(),
              label: s.name[0].toUpperCase() + s.name.substring(1),
              color: _severityColor(s),
            );
          }).toList(),
          holeRadius: 0.45,
          segmentGap: 2,
          showLabels: true,
          labelPosition: PieLabelPosition.outside,
          labelConnector: PieLabelConnector.elbow,
        ),
        centerWidget: Text(
          '${_alerts.length}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        tooltip: const TooltipConfig(enabled: true),
        animation: const ChartAnimation.none(),
      ),
    );
  }

  void _updateAlertStatus(TheftAlert alert) {
    final statusNotifier = ValueNotifier<TheftAlertStatus>(alert.status);
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FleetRadius.lg),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(FleetSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Update Alert Status', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: FleetSpacing.xs),
                  Text('${alert.vehicleName} - ${_typeLabel(alert.type)}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: FleetSpacing.lg),
                  ValueListenableBuilder<TheftAlertStatus>(
                    valueListenable: statusNotifier,
                    builder: (_, s, _) => DropdownButtonFormField<TheftAlertStatus>(
                      initialValue: s,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(FleetRadius.sm),
                        ),
                      ),
                      items: TheftAlertStatus.values.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(_statusLabel(s)),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) statusNotifier.value = v;
                      },
                    ),
                  ),
                  const SizedBox(height: FleetSpacing.md),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Add resolution details or investigation notes...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(FleetRadius.sm),
                      ),
                    ),
                  ),
                  const SizedBox(height: FleetSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: FleetSpacing.sm),
                      FilledButton(
                        onPressed: () {
                          if (noteCtrl.text.trim().isEmpty) return;
                          Navigator.pop(ctx, (statusNotifier.value, noteCtrl.text.trim()));
                        },
                        child: const Text('Update'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((result) async {
      if (result == null || !mounted) return;
      final (newStatus, note) = result as (TheftAlertStatus, String);

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FleetRadius.md),
          ),
          title: const Text('Confirm'),
          content: Text(
            'Update ${alert.vehicleName} alert to "${_statusLabel(newStatus)}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      final now = DateTime.now();
      int i;
      if (newStatus == TheftAlertStatus.resolved || newStatus == TheftAlertStatus.dismissed) {
        // Create updated alert (immutable pattern — rebuild)
        final updated = TheftAlert(
          id: alert.id,
          vehicleName: alert.vehicleName,
          plateNumber: alert.plateNumber,
          type: alert.type,
          severity: alert.severity,
          status: newStatus,
          timestamp: alert.timestamp,
          location: alert.location,
          description: alert.description,
          resolvedBy: 'Current User',
          resolvedAt: now,
        );
        setState(() {
          i = _alerts.indexWhere((a) => a.id == alert.id);
          if (i != -1) _alerts[i] = updated;
        });
      } else {
        setState(() {
          i = _alerts.indexWhere((a) => a.id == alert.id);
          if (i != -1) {
            _alerts[i] = TheftAlert(
            id: alert.id,
            vehicleName: alert.vehicleName,
            plateNumber: alert.plateNumber,
            type: alert.type,
            severity: alert.severity,
            status: newStatus,
            timestamp: alert.timestamp,
            location: alert.location,
            description: alert.description,
            resolvedBy: alert.resolvedBy,
            resolvedAt: alert.resolvedAt,
          );
          }
        });
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FleetRadius.md),
          ),
          title: const Text('Success'),
          content: Text(
            '${alert.vehicleName} alert updated to "${_statusLabel(newStatus)}".',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(FleetSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(FleetRadius.md),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(FleetSpacing.sm),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(FleetRadius.sm),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(FleetSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(FleetRadius.md),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  )),
                ],
              ),
              Icon(Icons.more_horiz, color: scheme.onSurfaceVariant, size: 18),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final TheftAlert alert;
  final String Function(TheftAlertType) typeLabel;
  final IconData Function(TheftAlertType) typeIcon;
  final Color Function(TheftAlertType) typeColor;
  final Color Function(TheftAlertSeverity) severityColor;
  final Color Function(TheftAlertStatus) statusColor;
  final String Function(TheftAlertStatus) statusLabel;
  final void Function(TheftAlert) onUpdateStatus;

  const _AlertCard({
    required this.alert,
    required this.typeLabel,
    required this.typeIcon,
    required this.typeColor,
    required this.severityColor,
    required this.statusColor,
    required this.statusLabel,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canAct = alert.status == TheftAlertStatus.newAlert || alert.status == TheftAlertStatus.investigating;

    return Container(
      padding: const EdgeInsets.all(FleetSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(FleetRadius.md),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(FleetSpacing.sm),
                decoration: BoxDecoration(
                  color: typeColor(alert.type).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(FleetRadius.sm),
                ),
                child: Icon(typeIcon(alert.type), size: 18, color: typeColor(alert.type)),
              ),
              const SizedBox(width: FleetSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(typeLabel(alert.type), style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                    const SizedBox(height: 2),
                    Text(alert.vehicleName, style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    )),
                  ],
                ),
              ),
              _Badge(label: statusLabel(alert.status), color: statusColor(alert.status)),
              const SizedBox(width: FleetSpacing.xs),
              _Badge(label: alert.severity.name[0].toUpperCase() + alert.severity.name.substring(1), color: severityColor(alert.severity)),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          Text(alert.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: FleetSpacing.sm),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 12, color: scheme.onSurfaceVariant),
              const SizedBox(width: FleetSpacing.xs),
              Text(alert.location, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
              const Spacer(),
              Icon(Icons.access_time, size: 12, color: scheme.onSurfaceVariant),
              const SizedBox(width: FleetSpacing.xs),
              Text(
                _formatTime(alert.timestamp),
                style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          if (alert.resolvedBy != null && alert.resolvedAt != null) ...[
            const SizedBox(height: FleetSpacing.xs),
            Row(
              children: [
                Icon(Icons.person_outline, size: 12, color: scheme.onSurfaceVariant),
                const SizedBox(width: FleetSpacing.xs),
                Text('Resolved by ${alert.resolvedBy}', style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                )),
                const SizedBox(width: FleetSpacing.md),
                Icon(Icons.check_circle, size: 12, color: AppTheme.successGreen),
                const SizedBox(width: FleetSpacing.xs),
                Text(
                  alert.resolvedAt!.toString().split(' ')[0],
                  style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.successGreen),
                ),
              ],
            ),
          ],
          if (canAct) ...[
            const SizedBox(height: FleetSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onUpdateStatus(alert),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Update Status'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(FleetRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
