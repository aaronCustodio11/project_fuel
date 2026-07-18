import 'package:chartify/chartify.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project_fuel/core/services/json_reader.dart';
import 'package:project_fuel/core/theme/app_theme.dart';
import 'package:project_fuel/shared/widgets/action_button.dart';

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
  final String reportedBy;
  final String supervisorName;

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
    required this.reportedBy,
    required this.supervisorName,
  });
}

class ManagerTheftDetection extends StatefulWidget {
  const ManagerTheftDetection({super.key});

  @override
  State<ManagerTheftDetection> createState() => _ManagerTheftDetectionState();
}

class _ManagerTheftDetectionState extends State<ManagerTheftDetection> {
  List<TheftAlert> _alerts = [];
  bool _isLoading = true;
  bool _showCharts = true;

  final _nextId = ValueNotifier<int>(8);

  late final Map<String, String> _vehicleSupervisorMap = {};
  late final Map<int, String> _supervisorNameMap = {};

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
        final role = u['role'] as String?;
        if (role == 'Supervisor') {
          _supervisorNameMap[id] = u['company'] as String? ?? userNameMap[id]!;
        }
      }
    }

    for (final v in vehicles) {
      final vm = v as Map<String, dynamic>;
      final sid = vm['supervisorId'] as int?;
      if (sid != null) {
        _vehicleSupervisorMap[vm['truckId'] as String] = _supervisorNameMap[sid] ?? 'Unknown Supervisor';
      }
    }

    final alerts = rawAlerts.whereType<Map<String, dynamic>>().map((a) {
      final vehicleId = a['vehicleId'] as String? ?? '';
      final vehicle = vehicleMap[vehicleId];
      final severityStr = a['severity'] as String? ?? 'medium';
      final typeStr = a['type'] as String? ?? 'fuelTheft';
      final isResolved = a['isResolved'] as bool? ?? false;
      final detectedBy = a['detectedBy'] as int?;

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
        status = a['resolvedBy'] != null ? TheftAlertStatus.resolved : TheftAlertStatus.dismissed;
      } else {
        status = TheftAlertStatus.newAlert;
      }

      final resolvedById = a['resolvedBy'] as int?;
      final sid = vehicle?['supervisorId'] as int?;

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
        reportedBy: detectedBy != null ? userNameMap[detectedBy] ?? 'Unknown' : 'Unknown',
        supervisorName: sid != null ? _supervisorNameMap[sid] ?? 'Unknown Supervisor' : 'Unknown Supervisor',
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
    TheftAlertStatus.newAlert => AppTheme.warningAmber,
    TheftAlertStatus.investigating => AppTheme.accentBlue,
    TheftAlertStatus.resolved => AppTheme.successGreen,
    TheftAlertStatus.dismissed => AppTheme.neutralGray500,
  };

  String _statusLabel(TheftAlertStatus s) => switch (s) {
    TheftAlertStatus.newAlert => 'Pending Review',
    TheftAlertStatus.investigating => 'Investigating',
    TheftAlertStatus.resolved => 'Resolved',
    TheftAlertStatus.dismissed => 'Dismissed',
  };

  void _showReportTheftDialog() {
    final formKey = GlobalKey<FormState>();
    final vehicleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedType;
    String? selectedSeverity;
    String? targetSupervisor;

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FleetRadius.lg),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(FleetSpacing.xl),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(FleetSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppTheme.dangerRed.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(FleetRadius.sm),
                          ),
                          child: const Icon(Icons.report_problem, color: AppTheme.dangerRed, size: 20),
                        ),
                        const SizedBox(width: FleetSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Report Theft Incident', style: theme.textTheme.headlineMedium),
                              Text('This will be sent to the vehicle\'s supervisor for review',
                                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: FleetSpacing.lg),
                    TextFormField(
                      controller: vehicleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle ID',
                        hintText: 'e.g. TRK-001',
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                      ),
                      onChanged: (v) {
                        final sid = _vehicleSupervisorMap[v.trim().toUpperCase()];
                        targetSupervisor = sid;
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter vehicle ID';
                        if (!_vehicleSupervisorMap.containsKey(v.trim().toUpperCase())) {
                          return 'Unknown vehicle';
                        }
                        return null;
                      },
                    ),
                    if (targetSupervisor != null) ...[
                      const SizedBox(height: FleetSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(FleetSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(FleetRadius.sm),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.send_rounded, size: 14, color: AppTheme.accentBlue),
                            const SizedBox(width: FleetSpacing.sm),
                            Text('Will be sent to $targetSupervisor',
                                style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.accentBlue)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: FleetSpacing.md),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Theft Type',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: TheftAlertType.values.map((t) => DropdownMenuItem(
                        value: t.name,
                        child: Text(_typeLabel(t)),
                      )).toList(),
                      onChanged: (v) => selectedType = v,
                      validator: (v) => v == null ? 'Select a type' : null,
                    ),
                    const SizedBox(height: FleetSpacing.md),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Severity',
                        prefixIcon: Icon(Icons.arrow_upward),
                      ),
                      items: TheftAlertSeverity.values.map((s) => DropdownMenuItem(
                        value: s.name,
                        child: Text(s.name[0].toUpperCase() + s.name.substring(1)),
                      )).toList(),
                      onChanged: (v) => selectedSeverity = v,
                      validator: (v) => v == null ? 'Select severity' : null,
                    ),
                    const SizedBox(height: FleetSpacing.md),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe what happened...',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter description' : null,
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
                        FilledButton.icon(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(ctx);
                              _submitReport(
                                vehicleCtrl.text.trim().toUpperCase(),
                                selectedType!,
                                selectedSeverity!,
                                descCtrl.text.trim(),
                              );
                            }
                          },
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text('Send to Supervisor'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _submitReport(String vehicleId, String typeStr, String severityStr, String description) {
    final id = 'THF-MGR-${_nextId.value}';
    _nextId.value++;
    final now = DateTime.now();

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

    final alert = TheftAlert(
      id: id,
      vehicleName: 'Truck #$vehicleId',
      plateNumber: '',
      type: type,
      severity: severity,
      status: TheftAlertStatus.newAlert,
      timestamp: now,
      location: '',
      description: description,
      reportedBy: 'Angela Lopez',
      supervisorName: _vehicleSupervisorMap[vehicleId] ?? 'Unknown Supervisor',
    );

    setState(() {
      _alerts.insert(0, alert);
    });

    _showReportSubmitted(alert.supervisorName);
  }

  void _showReportSubmitted(String supervisorName) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FleetRadius.md),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successGreen, size: 24),
            SizedBox(width: FleetSpacing.sm),
            Text('Report Sent'),
          ],
        ),
        content: Text(
          'Theft report has been sent to $supervisorName for review. '
          'You will be notified when the supervisor updates the status.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

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
    final pendingReview = _alerts.where((a) => a.status == TheftAlertStatus.newAlert).length;
    final investigating = _alerts.where((a) => a.status == TheftAlertStatus.investigating).length;
    final resolved = _alerts.where((a) => a.status == TheftAlertStatus.resolved || a.status == TheftAlertStatus.dismissed).length;

    final groupedStatus = TheftAlertStatus.values.map((s) {
      final items = _alerts.where((a) => a.status == s).toList();
      return (status: s, items: items);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(FleetSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Theft Detection', style: theme.textTheme.headlineLarge),
                    const SizedBox(height: 4),
                    Text('Report incidents to supervisors and track resolution',
                        style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActionButton(
                    icon: _showCharts ? Icons.visibility : Icons.visibility_off,
                    label: _showCharts ? 'Hide Charts' : 'Show Charts',
                    color: theme.colorScheme.primary,
                    onTap: () => setState(() => _showCharts = !_showCharts),
                  ),
                  const SizedBox(width: FleetSpacing.sm),
                  ActionButton(
                    icon: Icons.add_alert_rounded,
                    label: 'Report Theft',
                    color: AppTheme.dangerRed,
                    onTap: _showReportTheftDialog,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: FleetSpacing.lg),
          Row(
            children: [
              Expanded(child: _KpiCard(
                label: 'Total Sent', value: '$total',
                subtitle: 'Reports to supervisors', icon: Icons.send_rounded,
                accentColor: scheme.primary,
              )),
              const SizedBox(width: FleetSpacing.md),
              Expanded(child: _KpiCard(
                label: 'Pending Review', value: '$pendingReview',
                subtitle: 'Awaiting supervisor', icon: Icons.hourglass_empty,
                accentColor: AppTheme.warningAmber,
              )),
              const SizedBox(width: FleetSpacing.md),
              Expanded(child: _KpiCard(
                label: 'Investigating', value: '$investigating',
                subtitle: 'Supervisor acting', icon: Icons.search,
                accentColor: AppTheme.accentBlue,
              )),
              const SizedBox(width: FleetSpacing.md),
              Expanded(child: _KpiCard(
                label: 'Resolved', value: '$resolved',
                subtitle: 'Closed by supervisor', icon: Icons.check_circle_outline,
                accentColor: AppTheme.successGreen,
              )),
            ],
          ),
          const SizedBox(height: FleetSpacing.lg),
          if (_showCharts)
            SizedBox(
              height: 280,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _ChartCard(
                      title: 'Reports by Type',
                      subtitle: '$total total reports',
                      child: _buildTypeChart(),
                    ),
                  ),
                  const SizedBox(width: FleetSpacing.md),
                  Expanded(
                    flex: 2,
                    child: _ChartCard(
                      title: 'Severity Distribution',
                      subtitle: 'Breakdown of reports',
                      child: _buildSeverityChart(),
                    ),
                  ),
                  const SizedBox(width: FleetSpacing.md),
                  Expanded(
                    flex: 2,
                    child: _ChartCard(
                      title: 'Status Overview',
                      subtitle: 'Supervisor resolution progress',
                      child: _buildStatusChart(),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: FleetSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _statusGroup(
                  context,
                  TheftAlertStatus.newAlert,
                  groupedStatus.firstWhere((g) => g.status == TheftAlertStatus.newAlert).items,
                ),
              ),
              const SizedBox(width: FleetSpacing.md),
              Expanded(
                child: _statusGroup(
                  context,
                  TheftAlertStatus.resolved,
                  groupedStatus.firstWhere((g) => g.status == TheftAlertStatus.resolved).items,
                ),
              ),
            ],
          ),
          if (groupedStatus.any((g) => g.status == TheftAlertStatus.investigating && g.items.isNotEmpty) ||
              groupedStatus.any((g) => g.status == TheftAlertStatus.dismissed && g.items.isNotEmpty))
            const SizedBox(height: FleetSpacing.lg),
          ...groupedStatus.where((g) => g.status != TheftAlertStatus.newAlert && g.status != TheftAlertStatus.resolved).map((g) {
            if (g.items.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: FleetSpacing.lg),
              child: _statusGroup(context, g.status, g.items),
            );
          }),
        ],
      ),
    );
  }

  Widget _statusGroup(BuildContext context, TheftAlertStatus status, List<TheftAlert> items) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(FleetSpacing.xl),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(FleetRadius.md),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: FleetSpacing.sm),
                Text(_statusLabel(status), style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: FleetSpacing.md),
            Text('No ${_statusLabel(status).toLowerCase()} reports.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: FleetSpacing.sm),
                Text(_statusLabel(status), style: theme.textTheme.titleLarge),
              ],
            ),
            Text('${items.length} report${items.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: FleetSpacing.md),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: FleetSpacing.md),
          itemBuilder: (_, i) => _AlertCard(
            alert: items[i],
            typeLabel: _typeLabel,
            typeIcon: _typeIcon,
            typeColor: _typeColor,
            severityColor: _severityColor,
            statusColor: _statusColor,
            statusLabel: _statusLabel,
          ),
        ),
      ],
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
                name: 'Reports',
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

  Widget _buildSeverityChart() {
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

  Widget _buildStatusChart() {
    final counts = <TheftAlertStatus, int>{};
    for (final a in _alerts) {
      counts[a.status] = (counts[a.status] ?? 0) + 1;
    }
    final statuses = TheftAlertStatus.values;

    return RepaintBoundary(
      child: PieChart(
        data: PieChartData(
          sections: statuses.where((s) => (counts[s] ?? 0) > 0).map((s) {
            return PieSection(
              value: (counts[s] ?? 0).toDouble(),
              label: _statusLabel(s),
              color: _statusColor(s),
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

  const _AlertCard({
    required this.alert,
    required this.typeLabel,
    required this.typeIcon,
    required this.typeColor,
    required this.severityColor,
    required this.statusColor,
    required this.statusLabel,
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
              _Badge(
                label: alert.severity.name[0].toUpperCase() + alert.severity.name.substring(1),
                color: severityColor(alert.severity),
              ),
            ],
          ),
          const SizedBox(height: FleetSpacing.sm),
          Row(
            children: [
              Icon(Icons.business_outlined, size: 12, color: scheme.onSurfaceVariant),
              const SizedBox(width: FleetSpacing.xs),
              Text('Sent to ${alert.supervisorName}',
                  style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.accentBlue)),
              const Spacer(),
              Icon(Icons.access_time, size: 12, color: scheme.onSurfaceVariant),
              const SizedBox(width: FleetSpacing.xs),
              Text(
                _formatTime(alert.timestamp),
                style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          Text(alert.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: FleetSpacing.sm),
          Row(
            children: [
              Icon(Icons.person_outline, size: 12, color: scheme.onSurfaceVariant),
              const SizedBox(width: FleetSpacing.xs),
              Text('Reported by ${alert.reportedBy}',
                  style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
              if (alert.location.isNotEmpty) ...[
                const SizedBox(width: FleetSpacing.md),
                Icon(Icons.location_on_outlined, size: 12, color: scheme.onSurfaceVariant),
                const SizedBox(width: FleetSpacing.xs),
                Text(alert.location,
                    style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ],
          ),
          if (alert.resolvedBy != null && alert.resolvedAt != null) ...[
            const SizedBox(height: FleetSpacing.xs),
            Container(
              padding: const EdgeInsets.all(FleetSpacing.sm),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(FleetRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: AppTheme.successGreen),
                  const SizedBox(width: FleetSpacing.sm),
                  Text('Resolved by ${alert.resolvedBy} on ${alert.resolvedAt!.toString().split(' ')[0]}',
                      style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.successGreen)),
                ],
              ),
            ),
          ],
          if (alert.status == TheftAlertStatus.newAlert) ...[
            const SizedBox(height: FleetSpacing.md),
            Container(
              padding: const EdgeInsets.all(FleetSpacing.sm),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(FleetRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_empty, size: 14, color: AppTheme.warningAmber),
                  const SizedBox(width: FleetSpacing.sm),
                  Text('Awaiting review by ${alert.supervisorName}',
                      style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.warningAmber)),
                ],
              ),
            ),
          ],
          if (alert.status == TheftAlertStatus.investigating) ...[
            const SizedBox(height: FleetSpacing.md),
            Container(
              padding: const EdgeInsets.all(FleetSpacing.sm),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(FleetRadius.sm),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                  const SizedBox(width: FleetSpacing.sm),
                  Text('${alert.supervisorName} is investigating this report',
                      style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.accentBlue)),
                ],
              ),
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
