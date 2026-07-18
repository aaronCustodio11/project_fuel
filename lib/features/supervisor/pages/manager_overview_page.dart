import 'dart:math' as math;

import 'package:chartify/chartify.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project_fuel/core/models/order.dart';
import 'package:project_fuel/core/services/json_reader.dart';
import 'package:project_fuel/core/services/order_service.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

String? _coerceStringValue(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is Map) {
    final latitude = value['latitude'];
    final longitude = value['longitude'];
    if (latitude != null && longitude != null) {
      return '$latitude, $longitude';
    }
    return value.toString();
  }
  return value.toString();
}

class _ManagerStats {
  final String userId;
  final String fullName;
  final String email;
  final String company;
  final int teamSize;
  final int tasksAssigned;
  final int tasksCompleted;
  final double completionRate;
  final int pendingApprovals;
  final int overdueTasks;
  final double avgResponseHours;
  final DateTime? lastActivity;
  final bool isActive;
  final String location;

  const _ManagerStats({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.company,
    required this.teamSize,
    required this.tasksAssigned,
    required this.tasksCompleted,
    required this.completionRate,
    required this.pendingApprovals,
    required this.overdueTasks,
    required this.avgResponseHours,
    required this.lastActivity,
    required this.isActive,
    required this.location,
  });
}

class ManagerOverviewPage extends StatefulWidget {
  final List<Map<String, dynamic>> rawManagers;
  final VoidCallback onBack;

  const ManagerOverviewPage({
    super.key,
    required this.rawManagers,
    required this.onBack,
  });

  @override
  State<ManagerOverviewPage> createState() => _ManagerOverviewPageState();
}

class _ManagerOverviewPageState extends State<ManagerOverviewPage> {
  bool _isLoading = true;
  String? _errorMessage;

  List<_ManagerStats> _managerStats = [];

  int _totalActiveManagers = 0;
  int _totalInactiveManagers = 0;
  int _totalDrivers = 0;
  int _activeTasksToday = 0;
  int _pendingApprovalsTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final rawAuth = await JsonReaderService.readListStatic(
        'assets/mock_data/authentication.json',
      );
      final allUsers = rawAuth
          .whereType<Map<String, dynamic>>()
          .map((j) => _ManagedUserX.fromJson(j))
          .toList();

      final orderService = OrderService();
      final orders = await orderService.getOrders();

      final rawManagers =
          widget.rawManagers.map((j) => _ManagedUserX.fromJson(j)).toList();
      final allManagers = allUsers.where((u) => u.role == 'Manager').toList();
      final allDrivers = allUsers.where((u) => u.role == 'Driver').toList();

      final managersInView = rawManagers.isNotEmpty
          ? rawManagers
          : allManagers;

      final managerIds = managersInView.map((m) => m.userId).toSet();
      final managersInCompany = <String, List<_ManagedUserX>>{};
      for (final m in managersInView) {
        managersInCompany.putIfAbsent(m.company, () => []).add(m);
      }

      final driversByCompany = <String, List<_ManagedUserX>>{};
      for (final d in allDrivers) {
        driversByCompany.putIfAbsent(d.company, () => []).add(d);
      }

      final managerToDrivers = <String, List<_ManagedUserX>>{};
      for (final m in managersInView) {
        final companyDrivers = driversByCompany[m.company] ?? [];
        final companyManagers = managersInCompany[m.company] ?? [];
        final idx = companyManagers.indexOf(m);
        final chunkSize = companyDrivers.length >= companyManagers.length
            ? companyDrivers.length ~/ companyManagers.length
            : 1;
        final start = idx * chunkSize;
        final end = companyDrivers.length >= start + chunkSize
            ? start + chunkSize
            : companyDrivers.length;
        final assigned = start < companyDrivers.length
            ? companyDrivers.sublist(start, end > start ? end : start + 1)
            : <_ManagedUserX>[];
        managerToDrivers[m.userId] = assigned;
      }

      final rng = math.Random(42);

      final stats = managersInView.map((m) {
        final myOrders =
            orders.where((o) => o.createdBy.toString() == m.userId).toList();
        final assigned = myOrders.length;
        final completed =
            myOrders.where((o) => o.status == OrderStatus.completed).length;
        final pending = myOrders
            .where((o) => o.status == OrderStatus.pendingApproval)
            .length;
        final approved = myOrders.where((o) => o.status == OrderStatus.approved).length;

        final team = managerToDrivers[m.userId] ?? [];
        final teamSize = team.length;

        final overdueCount = myOrders
            .where((o) =>
                o.status == OrderStatus.pendingApproval &&
                o.createdAt.isBefore(
                    DateTime.now().subtract(const Duration(days: 2))))
            .length;

        double avgResponse = 0;
        final respondedOrders = myOrders
            .where((o) =>
                o.status != OrderStatus.pendingApproval &&
                o.approvedAt != null)
            .toList();
        if (respondedOrders.isNotEmpty) {
          final totalHours = respondedOrders.fold<double>(
            0,
            (sum, o) =>
                sum +
                o.approvedAt!.difference(o.createdAt).inMinutes /
                    60.0,
          );
          avgResponse = totalHours / respondedOrders.length;
        } else {
          avgResponse = rng.nextDouble() * 24 + 2;
        }

        final hoursAgo = rng.nextInt(72);
        final lastActivity =
            DateTime.now().subtract(Duration(hours: hoursAgo));
        final isActive = hoursAgo < 24;

        final loc = m.location ?? '';

        return _ManagerStats(
          userId: m.userId,
          fullName: m.fullName,
          email: m.email,
          company: m.company,
          teamSize: teamSize,
          tasksAssigned: assigned,
          tasksCompleted: completed + approved,
          completionRate: assigned > 0
              ? (completed + approved) / assigned
              : 0,
          pendingApprovals: pending,
          overdueTasks: overdueCount,
          avgResponseHours: double.parse(avgResponse.toStringAsFixed(1)),
          lastActivity: lastActivity,
          isActive: isActive,
          location: loc,
        );
      }).toList();

      final totalDrivers = managerToDrivers.values.fold<int>(0, (sum, list) => sum + list.length);

      final now = DateTime.now();
      final tasksToday = orders
          .where((o) =>
              o.createdAt.year == now.year &&
              o.createdAt.month == now.month &&
              o.createdAt.day == now.day &&
              managerIds.contains(o.createdBy.toString()))
          .length;

      final pendingApprovals = orders
          .where((o) =>
              o.status == OrderStatus.pendingApproval &&
              managerIds.contains(o.createdBy.toString()))
          .length;

      if (mounted) {
        setState(() {
          _managerStats = stats;
          _totalActiveManagers = stats.where((s) => s.isActive).length;
          _totalInactiveManagers = stats.where((s) => !s.isActive).length;
          _totalDrivers = totalDrivers;
          _activeTasksToday = tasksToday;
          _pendingApprovalsTotal = pendingApprovals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FleetSpacing.xl,
            FleetSpacing.xl,
            FleetSpacing.xl,
            0,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
                style: IconButton.styleFrom(
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: FleetSpacing.md),
              Text(
                'Managers Overview',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: LoadingAnimationWidget.staggeredDotsWave(
          color: Theme.of(context).colorScheme.primary,
          size: 50,
        ),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: AppTheme.dangerRed)),
            const SizedBox(height: FleetSpacing.md),
            OutlinedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(FleetSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKpiRow(context),
          const SizedBox(height: FleetSpacing.xl),
          _buildChartsRow(context),
          const SizedBox(height: FleetSpacing.xl),
          _buildManagerBreakdown(context),
          const SizedBox(height: FleetSpacing.xl),
          _buildAlertsSection(context),
          const SizedBox(height: FleetSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: FleetSpacing.md),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Total Managers',
                value: _managerStats.length.toString(),
                subtitle:
                    '$_totalActiveManagers active · $_totalInactiveManagers inactive',
                icon: Icons.badge_outlined,
                accentColor: AppTheme.accentBlue,
              ),
            ),
            const SizedBox(width: FleetSpacing.md),
            Expanded(
              child: _KpiCard(
                label: 'Drivers Under Mgmt',
                value: _totalDrivers.toString(),
                subtitle: 'Across ${_managerStats.length} managers',
                icon: Icons.groups_outlined,
                accentColor: AppTheme.successGreen,
              ),
            ),
            const SizedBox(width: FleetSpacing.md),
            Expanded(
              child: _KpiCard(
                label: 'Tasks Today',
                value: _activeTasksToday.toString(),
                subtitle: 'Assigned by managers',
                icon: Icons.assignment_outlined,
                accentColor: AppTheme.warningAmber,
              ),
            ),
            const SizedBox(width: FleetSpacing.md),
            Expanded(
              child: _KpiCard(
                label: 'Pending Approvals',
                value: _pendingApprovalsTotal.toString(),
                subtitle: 'Requiring supervisor action',
                icon: Icons.pending_actions_outlined,
                accentColor: AppTheme.dangerRed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartsRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: FleetSpacing.md),
        SizedBox(
          height: 300,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _ChartCard(
                  title: 'Tasks Assigned per Manager',
                  subtitle: 'Compare workload distribution',
                  child: _buildTasksBarChart(context),
                ),
              ),
              const SizedBox(width: FleetSpacing.md),
              Expanded(
                flex: 2,
                child: _ChartCard(
                  title: 'Driver Allocation',
                  subtitle: 'Team balance across managers',
                  child: _buildDriverAllocationPie(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FleetSpacing.md),
        SizedBox(
          height: 280,
          child: Row(
            children: [
              Expanded(
                child: _ChartCard(
                  title: 'Task Completion Trend',
                  subtitle: 'Last 7 days',
                  child: _buildCompletionTrendChart(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTasksBarChart(BuildContext context) {
    final names =
        _managerStats.map((s) => s.fullName.split(' ').first).toList();
    final assigned =
        _managerStats.map((s) => s.tasksAssigned.toDouble()).toList();
    final completed =
        _managerStats.map((s) => s.tasksCompleted.toDouble()).toList();
    final allValues = [...assigned, ...completed];
    final maxVal = allValues.isEmpty ? 0.0 : allValues.reduce((a, b) => a > b ? a : b);
    final maxTick = maxVal.ceil() + 1;

    return BarChart(
      data: BarChartData(
        series: [
          BarSeries.fromValues<double>(
            name: 'Assigned',
            values: assigned,
            color: AppTheme.accentBlue,
          ),
          BarSeries.fromValues<double>(
            name: 'Completed',
            values: completed,
            color: AppTheme.successGreen,
          ),
        ],
        xAxis: BarXAxisConfig(categories: names),
        yAxis: BarYAxisConfig(
          min: 0,
          max: maxTick.toDouble(),
          tickCount: 1,
          labelFormatter: (value) => value.toInt().toString(),
        ),
        grouping: BarGrouping.grouped,
        direction: BarDirection.vertical,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation.none(),
    );
  }

  Widget _buildDriverAllocationPie(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = [
      AppTheme.accentBlue,
      AppTheme.warningAmber,
      AppTheme.successGreen,
      AppTheme.dangerRed,
      AppTheme.brandBlueDark,
      AppTheme.neutralGray500,
    ];
    final names = _managerStats.map((s) => s.fullName.split(' ').first).toList();
    final teamSizes = _managerStats.map((s) => s.teamSize.toDouble()).toList();

    if (teamSizes.every((s) => s == 0)) {
      return Center(
        child: Text(
          'No driver assignments yet',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return PieChart(
      data: PieChartData(
        sections: List.generate(names.length, (i) {
          return PieSection(
            value: teamSizes[i],
            label: '${names[i]}: ${teamSizes[i].toInt()}',
            color: colors[i % colors.length],
          );
        }),
        segmentGap: 2,
        cornerRadius: 4,
        showLabels: true,
        labelPosition: PieLabelPosition.outside,
        labelConnector: PieLabelConnector.elbow,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation.none(),
    );
  }

  Widget _buildCompletionTrendChart(BuildContext context) {
    final rng = math.Random(42);

    final seriesList = _managerStats.map((s) {
      final values = List.generate(7, (i) {
        final base = s.tasksCompleted / 7.0;
        final noise = rng.nextDouble() * 2 - 1;
        return (base + noise).clamp(0, s.tasksAssigned.toDouble());
      });
      return LineSeries(
        name: s.fullName.split(' ').first,
        data: List.generate(7, (i) => DataPoint(x: i.toDouble(), y: values[i])),
        color: _managerColors[_managerStats.indexOf(s) % _managerColors.length],
        showMarkers: true,
        curved: true,
        strokeWidth: 2,
      );
    }).toList();

    final maxVal = _managerStats.fold<double>(0, (max, s) => math.max(max, s.tasksAssigned.toDouble()));
    final maxTick = math.max(maxVal.ceil() + 1, 5);

    return LineChart(
      data: LineChartData(
        series: seriesList,
        xAxis: const AxisConfig(label: 'Day'),
        yAxis: AxisConfig(
          label: 'Tasks',
          min: 0,
          max: maxTick.toDouble(),
          interval: 1,
          labelFormatter: (value) => value.toInt().toString(),
        ),
        showLegend: true,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation.none(),
    );
  }

  static const _managerColors = [
    Color(0xFF2E6FE0),
    Color(0xFFF5A623),
    Color(0xFF22C55E),
    Color(0xFFD93025),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
  ];

  Widget _buildManagerBreakdown(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Per-Manager Breakdown',
          style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: FleetSpacing.md),
        ..._managerStats.map((s) => _buildManagerCard(context, s)),
      ],
    );
  }

  Widget _buildManagerCard(BuildContext context, _ManagerStats s) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: FleetSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(FleetSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.12),
                  child: Text(
                    s.fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                    style: const TextStyle(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: FleetSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.fullName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        s.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(s.isActive),
              ],
            ),
            const Divider(height: FleetSpacing.xl),
            Row(
              children: [
                _MiniStat(label: 'Team Size', value: s.teamSize.toString()),
                _MiniStat(label: 'Assigned', value: s.tasksAssigned.toString()),
                _MiniStat(
                  label: 'Completed',
                  value: s.tasksCompleted.toString(),
                ),
                _MiniStat(
                  label: 'Completion',
                  value: '${(s.completionRate * 100).toInt()}%',
                ),
                _MiniStat(
                  label: 'Avg Response',
                  value: '${s.avgResponseHours.toStringAsFixed(0)}h',
                ),
              ],
            ),
            const SizedBox(height: FleetSpacing.sm),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  s.lastActivity != null
                      ? 'Last activity: ${_formatTimeAgo(s.lastActivity!)}'
                      : 'No activity recorded',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (s.pendingApprovals > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warningAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(FleetRadius.pill),
                    ),
                    child: Text(
                      '${s.pendingApprovals} pending',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.warningAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (s.overdueTasks > 0) ...[
                  const SizedBox(width: FleetSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(FleetRadius.pill),
                    ),
                    child: Text(
                      '${s.overdueTasks} overdue',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.dangerRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.successGreen.withValues(alpha: 0.12)
            : AppTheme.neutralGray500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(FleetRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.successGreen : AppTheme.neutralGray500,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? AppTheme.successGreen : AppTheme.neutralGray500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildAlertsSection(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final overdueManagers =
        _managerStats.where((s) => s.overdueTasks > 0).toList();
    final inactiveManagers =
        _managerStats.where((s) => !s.isActive).toList();
    final avgTeamSize = _managerStats.isEmpty
        ? 0.0
        : _managerStats.fold<double>(0, (sum, s) => sum + s.teamSize) /
            _managerStats.length;
    final unusualManagers = _managerStats.where((s) {
      if (avgTeamSize == 0) return false;
      return s.teamSize > avgTeamSize * 2 || s.teamSize == 0;
    }).toList();

    final hasAlerts = overdueManagers.isNotEmpty ||
        inactiveManagers.isNotEmpty ||
        unusualManagers.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Alerts & Flags',
              style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            if (hasAlerts) ...[
              const SizedBox(width: FleetSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(FleetRadius.pill),
                ),
                child: Text(
                  '${overdueManagers.length + inactiveManagers.length + unusualManagers.length} flags',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.dangerRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: FleetSpacing.md),
        if (!hasAlerts)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(FleetSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: AppTheme.successGreen),
                  const SizedBox(width: FleetSpacing.md),
                  Text(
                    'All managers are performing within normal parameters',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          )
        else ...[
          if (overdueManagers.isNotEmpty)
            _AlertCard(
              icon: Icons.warning_amber_rounded,
              iconColor: AppTheme.warningAmber,
              title: 'Managers with Overdue Tasks',
              subtitle: overdueManagers
                  .map((s) =>
                      '${s.fullName} (${s.overdueTasks} overdue)')
                  .join(', '),
            ),
          if (inactiveManagers.isNotEmpty)
            _AlertCard(
              icon: Icons.nights_stay_outlined,
              iconColor: AppTheme.neutralGray500,
              title: 'Inactive Managers',
              subtitle: inactiveManagers
                  .map((s) =>
                      '${s.fullName} — no activity in ${_formatTimeAgo(s.lastActivity!)}')
                  .join(', '),
            ),
          if (unusualManagers.isNotEmpty)
            _AlertCard(
              icon: Icons.scale_outlined,
              iconColor: AppTheme.accentBlue,
              title: 'Unusual Team Sizes',
              subtitle: unusualManagers
                  .map((s) {
                    if (s.teamSize == 0) return '${s.fullName} has no drivers';
                    return '${s.fullName} has ${s.teamSize} drivers (avg: ${avgTeamSize.toStringAsFixed(0)})';
                  })
                  .join(', '),
            ),
        ],
      ],
    );
  }
}

class _ManagedUserX {
  const _ManagedUserX({
    required this.userId,
    required this.firstName,
    this.middleName = '',
    required this.surName,
    this.extensionName = '',
    required this.company,
    required this.role,
    required this.email,
    this.location,
  });

  final String userId;
  final String firstName;
  final String middleName;
  final String surName;
  final String extensionName;
  final String company;
  final String role;
  final String email;
  final String? location;

  String get fullName {
    final parts = [
      firstName,
      if (middleName.trim().isNotEmpty) middleName,
      surName,
      if (extensionName.trim().isNotEmpty) extensionName,
    ];
    return parts.join(' ');
  }

  factory _ManagedUserX.fromJson(Map<String, dynamic> json) {
    return _ManagedUserX(
      userId: json['userId'].toString(),
      firstName: json['firstName'] as String? ?? '',
      middleName: json['middleName'] as String? ?? '',
      surName: json['surName'] as String? ?? '',
      extensionName: json['extensionName'] as String? ?? '',
      company: json['company'] as String? ?? '',
      role: json['role'] as String? ?? '',
      email: json['email'] as String? ?? '',
      location: _coerceStringValue(json['location']),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(FleetRadius.md),
        border: Border.all(color: scheme.outline),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(FleetRadius.md),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(FleetSpacing.md),
                child: Row(
                  children: [
                    Icon(icon, size: 22, color: accentColor),
                    const SizedBox(width: FleetSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            label,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          Text(
                            subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _AlertCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: FleetSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(FleetSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(FleetRadius.sm),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: FleetSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
