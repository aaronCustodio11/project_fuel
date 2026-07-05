import 'package:chartify/chartify.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project_fuel/core/models/maintenance.dart';
import 'package:project_fuel/core/services/json_reader.dart';
import 'package:project_fuel/core/services/maintenance_service.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

class SupplierMaintenance extends StatefulWidget {
  const SupplierMaintenance({super.key});

  @override
  State<SupplierMaintenance> createState() => _SupplierMaintenanceState();
}

class _SupplierMaintenanceState extends State<SupplierMaintenance> {
  List<MaintenanceRecord> _records = [];
  final Map<int, String> _userNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final results = await Future.wait([
      MaintenanceService().getRecords(),
      JsonReaderService.readListStatic('assets/mock_data/authentication.json'),
    ]);

    final records = results[0] as List<MaintenanceRecord>;
    final users = results[1];
    final names = <int, String>{};
    for (final u in users) {
      final id = u['userId'] as int?;
      if (id != null) {
        names[id] = '${u['firstName'] ?? ''} ${u['surName'] ?? ''}'.trim();
      }
    }

    if (mounted) {
      setState(() {
        _records = records;
        _userNames
          ..clear()
          ..addAll(names);
        _isLoading = false;
      });
    }
  }

  List<MaintenanceRecord> get _activeRecords =>
      _records.where((r) => r.status != MaintenanceStatus.completed && r.status != MaintenanceStatus.cancelled).toList();

  Future<void> _updateStatus(MaintenanceRecord record) async {
    final statusNotifier = ValueNotifier<MaintenanceStatus>(record.status);
    final noteCtrl = TextEditingController();

    final result = await showDialog<(MaintenanceStatus, String)?>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final scheme = theme.colorScheme;

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
                  Text('Update Status', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: FleetSpacing.xs),
                  Text('${record.vehicleName} - ${record.type}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: FleetSpacing.lg),
                  ValueListenableBuilder<MaintenanceStatus>(
                    valueListenable: statusNotifier,
                    builder: (_, s, _) => DropdownButtonFormField<MaintenanceStatus>(
                      initialValue: s,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(FleetRadius.sm),
                        ),
                      ),
                      items: MaintenanceStatus.values.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.label),
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
                      hintText: 'Describe what was done or why the status changed...',
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
                          final note = noteCtrl.text.trim();
                          if (note.isEmpty) return;
                          Navigator.pop(ctx, (statusNotifier.value, note));
                        },
                        child: const Text('Update Status'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == null || !mounted) return;
    final (newStatus, note) = result;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FleetRadius.md),
        ),
        title: const Text('Confirm'),
        content: Text(
          'Update ${record.vehicleName} status to "${newStatus.label}"?',
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
    final updated = record.copyWith(
      status: newStatus,
      completedDate: newStatus == MaintenanceStatus.completed ? now : record.completedDate,
      notes: [
        ...record.notes,
        MaintenanceNote(
          id: 'N-${DateTime.now().millisecondsSinceEpoch}',
          author: 'Current User',
          note: note,
          timestamp: now,
        ),
      ],
    );

    setState(() {
      final i = _records.indexWhere((r) => r.id == record.id);
      if (i != -1) _records[i] = updated;
    });

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FleetRadius.md),
        ),
        title: const Text('Success'),
        content: Text(
          '${record.vehicleName} status updated to "${newStatus.label}".',
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

    final total = _records.length;
    final inProgress = _records.where((r) => r.status == MaintenanceStatus.inProgress).length;
    final overdue = _records.where((r) => r.status == MaintenanceStatus.scheduled && r.scheduledDate != null && r.scheduledDate!.isBefore(DateTime.now())).length;
    final completed = _records.where((r) => r.status == MaintenanceStatus.completed).length;

    final byType = <String, int>{};
    for (final r in _records) {
      byType[r.type] = (byType[r.type] ?? 0) + 1;
    }

    final statusCounts = <MaintenanceStatus, int>{};
    for (final r in _records) {
      statusCounts[r.status] = (statusCounts[r.status] ?? 0) + 1;
    }

    final costByType = <String, int>{};
    for (final r in _records) {
      costByType[r.type] = (costByType[r.type] ?? 0) + r.cost.round();
    }
    final costTypeLabels = costByType.keys.take(6).toList();
    final costTypeValues = costTypeLabels.map((l) => costByType[l]!.toDouble()).toList();

    final totalCost = _records.fold<int>(0, (s, r) => s + r.cost.round());
    final avgCost = _records.isNotEmpty ? totalCost ~/ _records.length : 0;
    final highestCost = _records.fold<int>(0, (m, r) => r.cost > m ? r.cost.round() : m);
    final inProgCost = _records.where((r) => r.status == MaintenanceStatus.inProgress).fold<int>(0, (s, r) => s + r.cost.round());
    final completedCost = _records.where((r) => r.status == MaintenanceStatus.completed).fold<int>(0, (s, r) => s + r.cost.round());

    final typeLabels = byType.keys.take(6).toList();
    final typeValues = typeLabels.map((l) => byType[l]!.toDouble()).toList();

    return Padding(
      padding: const EdgeInsets.all(FleetSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Maintenance', style: theme.textTheme.headlineLarge),
              Text('${_activeRecords.length} active', style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              )),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildKpiRow(context, total, inProgress, overdue, completed),
                  const SizedBox(height: FleetSpacing.xl),
                  _buildCostAnalytics(context, totalCost, avgCost, highestCost, inProgCost, completedCost,
                      costTypeLabels, costTypeValues),
                  const SizedBox(height: FleetSpacing.xl),
                  SizedBox(height: 320, child: _buildChartsRow(context, typeLabels, typeValues, statusCounts)),
                  const SizedBox(height: FleetSpacing.xl),
                  _buildRecordsList(context),
                  const SizedBox(height: FleetSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context, int total, int inProgress, int overdue, int completed) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(child: _KpiCard(
          label: 'Total Requests',
          value: '$total',
          subtitle: 'All time',
          icon: Icons.build_outlined,
          accentColor: scheme.primary,
          trend: '${_activeRecords.length} active',
          trendUp: true,
        )),
        const SizedBox(width: FleetSpacing.md),
        Expanded(child: _KpiCard(
          label: 'In Progress',
          value: '$inProgress',
          subtitle: 'Currently being worked on',
          icon: Icons.engineering_outlined,
          accentColor: AppTheme.warningAmber,
          trend: '$inProgress active',
          trendUp: true,
        )),
        const SizedBox(width: FleetSpacing.md),
        Expanded(child: _KpiCard(
          label: 'Overdue',
          value: '$overdue',
          subtitle: 'Past scheduled date',
          icon: Icons.warning_amber_outlined,
          accentColor: AppTheme.dangerRed,
          trend: '$overdue needs attention',
          trendUp: false,
        )),
        const SizedBox(width: FleetSpacing.md),
        Expanded(child: _KpiCard(
          label: 'Completed',
          value: '$completed',
          subtitle: 'This period',
          icon: Icons.check_circle_outline,
          accentColor: AppTheme.successGreen,
          trend: '${total > 0 ? (completed * 100 ~/ total) : 0}% completion',
          trendUp: true,
        )),
      ],
    );
  }

  Widget _buildCostAnalytics(BuildContext context, int totalCost, int avgCost, int highestCost,
      int inProgCost, int completedCost, List<String> typeLabels, List<double> typeValues) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    String fmt(int v) => '₱${v >= 1000 ? '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k' : '$v'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Cost Analytics', style: theme.textTheme.titleLarge),
            Text('₱${totalCost.toStringAsFixed(0)} total', style: theme.textTheme.labelLarge?.copyWith(
              color: AppTheme.successGreen, fontWeight: FontWeight.w600,
            )),
          ],
        ),
        const SizedBox(height: FleetSpacing.md),
        Row(
          children: [
            Expanded(child: _CostKpiCard(
              label: 'Total Spent', value: fmt(totalCost),
              subtitle: 'All maintenance requests',
              icon: Icons.account_balance_wallet_outlined,
              color: scheme.primary,
            )),
            const SizedBox(width: FleetSpacing.md),
            Expanded(child: _CostKpiCard(
              label: 'Avg per Request', value: fmt(avgCost),
              subtitle: '${_records.length} requests',
              icon: Icons.bar_chart_outlined,
              color: AppTheme.accentBlue,
            )),
            const SizedBox(width: FleetSpacing.md),
            Expanded(child: _CostKpiCard(
              label: 'In Progress', value: fmt(inProgCost),
              subtitle: 'Ongoing work',
              icon: Icons.engineering_outlined,
              color: AppTheme.warningAmber,
            )),
            const SizedBox(width: FleetSpacing.md),
            Expanded(child: _CostKpiCard(
              label: 'Completed', value: fmt(completedCost),
              subtitle: 'Finished work',
              icon: Icons.check_circle_outlined,
              color: AppTheme.successGreen,
            )),
          ],
        ),
        const SizedBox(height: FleetSpacing.md),
        SizedBox(
          height: 180,
          child: _ChartCard(
            title: 'Cost by Type',
            subtitle: 'Total spending per maintenance category',
            child: RepaintBoundary(
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
                        name: 'Cost',
                        values: typeValues,
                        color: AppTheme.successGreen,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF34D399)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ],
                    xAxis: BarXAxisConfig(categories: typeLabels),
                    yAxis: const BarYAxisConfig(min: 0, tickCount: 4),
                    grouping: BarGrouping.grouped,
                    direction: BarDirection.vertical,
                  ),
                  tooltip: const TooltipConfig(enabled: true),
                  animation: const ChartAnimation.none(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartsRow(BuildContext context, List<String> typeLabels, List<double> typeValues, Map<MaintenanceStatus, int> statusCounts) {
    final statusColors = {
      MaintenanceStatus.scheduled: AppTheme.accentBlue,
      MaintenanceStatus.inProgress: AppTheme.warningAmber,
      MaintenanceStatus.completed: AppTheme.successGreen,
      MaintenanceStatus.cancelled: AppTheme.neutralGray500,
    };

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _ChartCard(
            title: 'Requests by Type',
            subtitle: '${_records.length} total requests',
            child: RepaintBoundary(
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
                        name: 'Requests',
                        values: typeValues,
                        color: const Color(0xFF6366F1),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ],
                    xAxis: BarXAxisConfig(categories: typeLabels),
                    yAxis: const BarYAxisConfig(min: 0, tickCount: 4),
                    grouping: BarGrouping.grouped,
                    direction: BarDirection.vertical,
                  ),
                  tooltip: const TooltipConfig(enabled: true),
                  animation: const ChartAnimation.none(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: FleetSpacing.md),
        Expanded(
          flex: 2,
          child: _ChartCard(
            title: 'Status Distribution',
            subtitle: 'Current breakdown',
            child: RepaintBoundary(
              child: PieChart(
                data: PieChartData(
                  sections: MaintenanceStatus.values.where((s) => (statusCounts[s] ?? 0) > 0).map((s) {
                    return PieSection(
                      value: (statusCounts[s] ?? 0).toDouble(),
                      label: s.label,
                      color: statusColors[s]!,
                    );
                  }).toList(),
                  holeRadius: 0.45,
                  segmentGap: 2,
                  showLabels: true,
                  labelPosition: PieLabelPosition.outside,
                  labelConnector: PieLabelConnector.elbow,
                ),
                centerWidget: Text(
                  '${_records.length}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                tooltip: const TooltipConfig(enabled: true),
                animation: const ChartAnimation.none(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordsList(BuildContext context) {
    final theme = Theme.of(context);

    final active = _activeRecords;
    final completed = _records.where((r) => r.status == MaintenanceStatus.completed || r.status == MaintenanceStatus.cancelled).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Active Requests', style: theme.textTheme.titleLarge),
              const SizedBox(height: FleetSpacing.md),
              if (active.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(FleetSpacing.xl),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(FleetRadius.md),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Text('No active maintenance requests.', style: theme.textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
                )
              else
                ...active.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: FleetSpacing.md),
                  child: _MaintenanceCard(
                    record: r,
                    onUpdateStatus: () => _updateStatus(r),
                    userNames: _userNames,
                  ),
                )),
            ],
          ),
        ),
        const SizedBox(width: FleetSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Completed & Cancelled', style: theme.textTheme.titleLarge),
              const SizedBox(height: FleetSpacing.md),
              if (completed.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(FleetSpacing.xl),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(FleetRadius.md),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Text('No completed or cancelled requests.', style: theme.textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
                )
              else
                ...completed.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: FleetSpacing.md),
                  child: _MaintenanceCard(
                    record: r,
                    onUpdateStatus: () => _updateStatus(r),
                    userNames: _userNames,
                  ),
                )),
            ],
          ),
        ),
      ],
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  final MaintenanceRecord record;
  final VoidCallback onUpdateStatus;
  final Map<int, String> userNames;

  const _MaintenanceCard({required this.record, required this.onUpdateStatus, this.userNames = const {}});

  Color _statusColor(MaintenanceStatus s) => switch (s) {
    MaintenanceStatus.scheduled => AppTheme.accentBlue,
    MaintenanceStatus.inProgress => AppTheme.warningAmber,
    MaintenanceStatus.completed => AppTheme.successGreen,
    MaintenanceStatus.cancelled => AppTheme.neutralGray500,
  };

  Color _priorityColor(MaintenancePriority p) => switch (p) {
    MaintenancePriority.low => AppTheme.accentBlue,
    MaintenancePriority.medium => AppTheme.warningAmber,
    MaintenancePriority.high => AppTheme.dangerRed,
    MaintenancePriority.critical => AppTheme.dangerRed,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canUpdate = record.status != MaintenanceStatus.completed && record.status != MaintenanceStatus.cancelled;

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
                  color: _statusColor(record.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(FleetRadius.sm),
                ),
                child: Icon(Icons.build_outlined, size: 18, color: _statusColor(record.status)),
              ),
              const SizedBox(width: FleetSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.type, style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                    const SizedBox(height: 2),
                    Text(record.vehicleName, style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    )),
                  ],
                ),
              ),
              _Badge(label: record.status.label, color: _statusColor(record.status)),
              const SizedBox(width: FleetSpacing.xs),
              _Badge(label: record.priority.label, color: _priorityColor(record.priority)),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          Text(record.description, style: theme.textTheme.bodyMedium),
          if (record.scheduledDate != null) ...[
            const SizedBox(height: FleetSpacing.sm),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: scheme.onSurfaceVariant),
                const SizedBox(width: FleetSpacing.xs),
                Text(
                  'Scheduled: ${record.scheduledDate!.toString().split(' ')[0]}',
                  style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                if (record.completedDate != null) ...[
                  const SizedBox(width: FleetSpacing.md),
                  Icon(Icons.check_circle, size: 12, color: AppTheme.successGreen),
                  const SizedBox(width: FleetSpacing.xs),
                  Text(
                    'Completed: ${record.completedDate!.toString().split(' ')[0]}',
                    style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.successGreen),
                  ),
                ],
              ],
            ),
          ],
          if (record.assignedToId != null) ...[
            const SizedBox(height: FleetSpacing.xs),
            Row(
              children: [
                Icon(Icons.person_outline, size: 12, color: scheme.onSurfaceVariant),
                const SizedBox(width: FleetSpacing.xs),
                Text(userNames[record.assignedToId] ?? 'User #${record.assignedToId}',
                    style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                )),
                const Spacer(),
                Text('₱${record.cost.toStringAsFixed(0)}', style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.successGreen,
                )),
              ],
            ),
          ],
          if (record.notes.isNotEmpty) ...[
            const SizedBox(height: FleetSpacing.sm),
            const Divider(height: 1),
            ...record.notes.reversed.take(2).map((n) => Padding(
              padding: const EdgeInsets.only(top: FleetSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 12, color: scheme.onSurfaceVariant),
                  const SizedBox(width: FleetSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.note, style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        )),
                        const SizedBox(height: 1),
                        Text('${n.author} - ${n.timestamp.toString().split(' ')[0]}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                              fontSize: 10,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            if (record.notes.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: FleetSpacing.xs),
                child: Text('+${record.notes.length - 2} more notes',
                    style: theme.textTheme.labelSmall?.copyWith(color: scheme.primary)),
              ),
          ],
          if (canUpdate) ...[
            const SizedBox(height: FleetSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onUpdateStatus,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Update Status'),
              ),
            ),
          ],
        ],
      ),
    );
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

class _CostKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _CostKpiCard({required this.label, required this.value, required this.subtitle, required this.icon, required this.color});

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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(FleetRadius.sm),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.trend,
    required this.trendUp,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String trend;
  final bool trendUp;

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
                child: Icon(icon, size: 18, color: accentColor),
              ),
              Icon(
                trendUp ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: trendUp ? Colors.green : AppTheme.dangerRed,
              ),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: FleetSpacing.xs),
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          )),
          const SizedBox(height: FleetSpacing.xs),
          Row(
            children: [
              Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              )),
              const Spacer(),
              Text(trend, style: theme.textTheme.labelSmall?.copyWith(
                color: trendUp ? Colors.green : AppTheme.dangerRed,
                fontWeight: FontWeight.w600,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

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
