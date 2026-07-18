import 'dart:math' as math;

import 'package:chartify/chartify.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project_fuel/core/services/deliveries.dart';
import 'package:project_fuel/core/services/json_reader.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

String? _coerceString(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is Map) {
    final lat = value['latitude'];
    final lng = value['longitude'];
    if (lat != null && lng != null) return '$lat, $lng';
    return value.toString();
  }
  return value.toString();
}

class _DriverStats {
  final String userId;
  final String fullName;
  final String email;
  final String plateNumber;
  final String company;
  final String? assignedManagerName;
  final int tripsAssigned;
  final int tripsCompleted;
  final double completionRate;
  final double onTimeRate;
  final double distanceKm;
  final double hoursActive;
  final String status;
  final String? location;
  final bool isFlagged;
  final String? flagReason;

  const _DriverStats({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.plateNumber,
    required this.company,
    this.assignedManagerName,
    required this.tripsAssigned,
    required this.tripsCompleted,
    required this.completionRate,
    required this.onTimeRate,
    required this.distanceKm,
    required this.hoursActive,
    required this.status,
    this.location,
    this.isFlagged = false,
    this.flagReason,
  });
}

class DriverOverviewPage extends StatefulWidget {
  final List<Map<String, dynamic>> rawDrivers;
  final VoidCallback onBack;

  const DriverOverviewPage({
    super.key,
    required this.rawDrivers,
    required this.onBack,
  });

  @override
  State<DriverOverviewPage> createState() => _DriverOverviewPageState();
}

class _DriverOverviewPageState extends State<DriverOverviewPage> {
  bool _isLoading = true;
  String? _errorMessage;

  List<_DriverStats> _driverStats = [];

  int _activeDrivers = 0;
  int _onTripDrivers = 0;
  int _offlineDrivers = 0;
  int _tripsCompletedToday = 0;
  double _overallOnTimeRate = 0;
  int _flaggedCount = 0;

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
          .map((j) => _ManagedUserY.fromJson(j))
          .toList();

      final deliveryService = DeliveryService();
      final deliveries = await deliveryService.getAllDeliveries();
      final trucks = await deliveryService.getAllTruckData();

      final rawDrivers =
          widget.rawDrivers.map((j) => _ManagedUserY.fromJson(j)).toList();
      final allManagers = allUsers.where((u) => u.role == 'Manager').toList();

      final rng = math.Random(84);

      final driverStats = rawDrivers.map((d) {
        final truck = trucks.where((t) => t.driverId.toString() == d.userId).firstOrNull;
        final status = truck?.status ?? 'Offline';

        final driverDeliveries = truck != null
            ? deliveries.where((del) => del.truckId == truck.truckId).toList()
            : <DeliveryModel>[];
        final assigned = driverDeliveries.length;
        final completed =
            driverDeliveries.where((del) => del.status == 'completed').length;

        final onTimeDeliveries = driverDeliveries.where((del) {
          if (del.status != 'completed' ||
              del.scheduledDate == null ||
              del.completedDate == null) {
            return false;
          }
          return del.completedDate!.isBefore(del.scheduledDate!.add(const Duration(hours: 2)));
        }).length;
        final onTimeRate =
            completed > 0 ? onTimeDeliveries / completed : rng.nextDouble() * 0.3 + 0.6;

        final baseTrips = completed + (driverDeliveries.where((del) => del.status == 'inProgress').length);
        final distance = baseTrips * (rng.nextDouble() * 60 + 20);
        final hours = baseTrips * (rng.nextDouble() * 1.5 + 0.5);

        final sameCompanyManagers = allManagers
            .where((m) => m.company == d.company)
            .toList();
        String? managerName;
        if (sameCompanyManagers.isNotEmpty) {
          final idx = int.tryParse(d.userId) ?? 0;
          managerName =
              sameCompanyManagers[idx % sameCompanyManagers.length].fullName;
        }

        final isFlagged = rng.nextDouble() < 0.2;
        String? flagReason;
        if (isFlagged) {
          final reasons = [
            'Repeated late deliveries',
            'Low customer rating',
            'Incident reported',
            'Missed check-in',
            'Overtime limit exceeded',
          ];
          flagReason = reasons[rng.nextInt(reasons.length)];
        }

        return _DriverStats(
          userId: d.userId,
          fullName: d.fullName,
          email: d.email,
          plateNumber: d.plateNumber ?? truck?.plateNumber ?? '—',
          company: d.company,
          assignedManagerName: managerName,
          tripsAssigned: assigned,
          tripsCompleted: completed,
          completionRate: assigned > 0 ? completed / assigned : 0,
          onTimeRate: double.parse((onTimeRate * 100).toStringAsFixed(0)),
          distanceKm: double.parse(distance.toStringAsFixed(0)),
          hoursActive: double.parse(hours.toStringAsFixed(1)),
          status: status,
          location: _coerceString(d.location),
          isFlagged: isFlagged,
          flagReason: flagReason,
        );
      }).toList();

      final now = DateTime.now();
      final completedToday = deliveries.where((del) {
        if (del.completedDate == null) return false;
        return del.completedDate!.year == now.year &&
            del.completedDate!.month == now.month &&
            del.completedDate!.day == now.day &&
            driverStats.any((ds) {
              final truck = trucks.where((t) => t.driverId.toString() == ds.userId).firstOrNull;
              return truck != null && del.truckId == truck.truckId;
            });
      }).length;

      final active = driverStats.where((s) => s.status == 'Idle').length;
      final onTrip = driverStats.where((s) => s.status == 'En Route').length;
      final offline = driverStats.where((s) => s.status == 'Offline' || s.status == 'Maintenance').length;
      final flagged = driverStats.where((s) => s.isFlagged).length;

      final allRates = driverStats.map((s) => s.onTimeRate);
      final avgOnTime = allRates.isEmpty
          ? 0.0
          : allRates.reduce((a, b) => a + b) / allRates.length;

      if (mounted) {
        setState(() {
          _driverStats = driverStats;
          _activeDrivers = active;
          _onTripDrivers = onTrip;
          _offlineDrivers = offline;
          _tripsCompletedToday = completedToday;
          _overallOnTimeRate = double.parse(avgOnTime.toStringAsFixed(0));
          _flaggedCount = flagged;
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
                'Drivers Overview',
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
          _buildDriverBreakdown(context),
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
                label: 'Total Drivers',
                value: _driverStats.length.toString(),
                subtitle: '$_activeDrivers idle · $_onTripDrivers en route · $_offlineDrivers offline',
                icon: Icons.local_shipping_outlined,
                accentColor: AppTheme.accentBlue,
              ),
            ),
            const SizedBox(width: FleetSpacing.md),
            Expanded(
              child: _KpiCard(
                label: 'Trips Completed Today',
                value: _tripsCompletedToday.toString(),
                subtitle: 'Across all drivers',
                icon: Icons.check_circle_outline,
                accentColor: AppTheme.successGreen,
              ),
            ),
            const SizedBox(width: FleetSpacing.md),
            Expanded(
              child: _KpiCard(
                label: 'On-Time Rate',
                value: '${_overallOnTimeRate.toInt()}%',
                subtitle: 'Delivery punctuality',
                icon: Icons.schedule_outlined,
                accentColor: AppTheme.warningAmber,
              ),
            ),
            const SizedBox(width: FleetSpacing.md),
            Expanded(
              child: _KpiCard(
                label: 'Flagged Drivers',
                value: _flaggedCount.toString(),
                subtitle: 'Requires attention',
                icon: Icons.flag_outlined,
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
                  title: 'Trips Completed per Driver',
                  subtitle: 'Leaderboard view',
                  child: _buildTripsBarChart(context),
                ),
              ),
              const SizedBox(width: FleetSpacing.md),
              Expanded(
                flex: 2,
                child: _ChartCard(
                  title: 'Status Distribution',
                  subtitle: 'Current driver states',
                  child: _buildStatusPieChart(context),
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
                flex: 3,
                child: _ChartCard(
                  title: 'Completion Rate Trend',
                  subtitle: 'Last 7 days',
                  child: _buildCompletionTrend(context),
                ),
              ),
              const SizedBox(width: FleetSpacing.md),
              Expanded(
                flex: 2,
                child: _ChartCard(
                  title: 'Activity Heatmap',
                  subtitle: 'Peak hours (24h)',
                  child: _buildHeatmap(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripsBarChart(BuildContext context) {
    final sorted = List<_DriverStats>.from(_driverStats)
      ..sort((a, b) => b.tripsCompleted.compareTo(a.tripsCompleted));
    final top = sorted.take(10).toList();

    final names = top.map((s) {
      final parts = s.fullName.split(' ');
      return parts.first;
    }).toList();
    final completed = top.map((s) => s.tripsCompleted.toDouble()).toList();
    final assigned = top.map((s) => s.tripsAssigned.toDouble()).toList();

    return BarChart(
      data: BarChartData(
        series: [
          BarSeries.fromValues<double>(
            name: 'Completed',
            values: completed,
            color: AppTheme.successGreen,
          ),
          BarSeries.fromValues<double>(
            name: 'Assigned',
            values: assigned,
            color: AppTheme.accentBlue.withValues(alpha: 0.5),
          ),
        ],
        xAxis: BarXAxisConfig(categories: names),
        yAxis: BarYAxisConfig(
          min: 0,
          max: [...completed, ...assigned].isEmpty
              ? 3
              : ([...completed, ...assigned].reduce((a, b) => a > b ? a : b).ceil() + 1).toDouble(),
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

  Widget _buildStatusPieChart(BuildContext context) {
    final idleCount = _driverStats.where((s) => s.status == 'Idle').length.toDouble();
    final enrouteCount = _driverStats.where((s) => s.status == 'En Route').length.toDouble();
    final maintenanceCount = _driverStats.where((s) => s.status == 'Maintenance').length.toDouble();
    final offlineCount = _driverStats.where((s) =>
        s.status != 'Idle' && s.status != 'En Route' && s.status != 'Maintenance').length.toDouble();

    final sections = <PieSection>[];
    if (idleCount > 0) {
      sections.add(PieSection(
        value: idleCount,
        label: 'Idle',
        color: AppTheme.neutralGray500,
      ));
    }
    if (enrouteCount > 0) {
      sections.add(PieSection(
        value: enrouteCount,
        label: 'En Route',
        color: AppTheme.accentBlue,
      ));
    }
    if (maintenanceCount > 0) {
      sections.add(PieSection(
        value: maintenanceCount,
        label: 'Maintenance',
        color: AppTheme.warningAmber,
      ));
    }
    if (offlineCount > 0) {
      sections.add(PieSection(
        value: offlineCount,
        label: 'Offline',
        color: AppTheme.dangerRed,
      ));
    }

    return PieChart(
      data: PieChartData(
        sections: sections,
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

  Widget _buildCompletionTrend(BuildContext context) {
    final rng = math.Random(84);

    final seriesList = _driverStats.map((s) {
      final base = s.tripsCompleted / 7.0;
      final values = List.generate(7, (i) {
        final noise = rng.nextDouble() * 1.5 - 0.75;
        return (base + noise).clamp(0, s.tripsAssigned.toDouble());
      });
      return LineSeries(
        name: s.fullName.split(' ').first,
        data: List.generate(7, (i) => DataPoint(x: i.toDouble(), y: values[i])),
        color: _driverColors[_driverStats.indexOf(s) % _driverColors.length],
        showMarkers: true,
        curved: true,
        strokeWidth: 2,
      );
    }).toList();

    final maxVal = _driverStats.fold<double>(0, (max, s) => math.max(max, s.tripsAssigned.toDouble()));
    final maxTick = math.max(maxVal.ceil() + 1, 5);

    return LineChart(
      data: LineChartData(
        series: seriesList,
        xAxis: const AxisConfig(label: 'Day'),
        yAxis: AxisConfig(
          label: 'Trips',
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

  Widget _buildHeatmap(BuildContext context) {
    final rng = math.Random(84);
    final hours = List.generate(8, (i) => '${(i + 6) % 24}:00');
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final data = List.generate(days.length, (d) {
      return List<double>.generate(hours.length, (h) {
        final active = _driverStats.where((s) => s.status == 'En Route').length;
        final base = active / 2.0;
        final peak = (h >= 2 && h <= 4) ? 2.0 : 0.0;
        final weekend = d >= 5 ? -1.0 : 0.0;
        return (base + peak + weekend + rng.nextDouble() * 2).clamp(0, _driverStats.length.toDouble()) as double;
      });
    });

    return HeatmapChart(
      data: HeatmapChartData(
        data: data,
        rowLabels: days,
        columnLabels: hours,
        colorScale: HeatmapColorScale.blues,
        showValues: true,
        cellBorderRadius: 3,
      ),
      tooltip: const TooltipConfig(enabled: true),
      animation: const ChartAnimation.none(),
    );
  }

  static const _driverColors = [
    Color(0xFF2E6FE0),
    Color(0xFFF5A623),
    Color(0xFF22C55E),
    Color(0xFFD93025),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF6366F1),
  ];

  Widget _buildDriverBreakdown(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Per-Driver Breakdown',
          style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: FleetSpacing.md),
        ..._driverStats.map((s) => _buildDriverCard(context, s)),
      ],
    );
  }

  Widget _buildDriverCard(BuildContext context, _DriverStats s) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Color statusColor;
    switch (s.status) {
      case 'En Route':
        statusColor = AppTheme.accentBlue;
        break;
      case 'Idle':
        statusColor = AppTheme.neutralGray500;
        break;
      case 'Maintenance':
        statusColor = AppTheme.warningAmber;
        break;
      default:
        statusColor = AppTheme.dangerRed;
    }

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
                      Row(
                        children: [
                          Text(
                            s.fullName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (s.isFlagged) ...[
                            const SizedBox(width: FleetSpacing.sm),
                            Icon(Icons.flag, size: 16, color: AppTheme.dangerRed),
                          ],
                        ],
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
                _buildStatusPill(s.status, statusColor),
              ],
            ),
            const Divider(height: FleetSpacing.xl),
            Row(
              children: [
                _MiniStat(label: 'Plate', value: s.plateNumber),
                _MiniStat(label: 'Trips', value: '${s.tripsCompleted}/${s.tripsAssigned}'),
                _MiniStat(
                  label: 'Completion',
                  value: '${(s.completionRate * 100).toInt()}%',
                ),
                _MiniStat(label: 'On-Time', value: '${s.onTimeRate.toInt()}%'),
                _MiniStat(label: 'Dist(km)', value: s.distanceKm.toStringAsFixed(0)),
                _MiniStat(label: 'Hours', value: s.hoursActive.toStringAsFixed(0)),
              ],
            ),
            const SizedBox(height: FleetSpacing.sm),
            Row(
              children: [
                if (s.assignedManagerName != null) ...[
                  Icon(Icons.person_outline, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Mgr: ${s.assignedManagerName}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: FleetSpacing.md),
                ],
                if (s.location != null && s.location!.isNotEmpty) ...[
                  Icon(Icons.location_on_outlined, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      s.location!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (s.isFlagged && s.flagReason != null) ...[
              const SizedBox(height: FleetSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(FleetRadius.sm),
                  border: Border.all(
                    color: AppTheme.dangerRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 14, color: AppTheme.dangerRed),
                    const SizedBox(width: 6),
                    Text(
                      s.flagReason!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.dangerRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(FleetRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final flaggedDrivers = _driverStats.where((s) => s.isFlagged).toList();
    final offlineDrivers =
        _driverStats.where((s) => s.status == 'Offline').toList();
    final lowCompletion = _driverStats
        .where((s) => s.tripsAssigned > 2 && s.completionRate < 0.4)
        .toList();
    final lowOnTime = _driverStats
        .where((s) => s.tripsCompleted > 0 && s.onTimeRate < 50)
        .toList();

    final hasAlerts = flaggedDrivers.isNotEmpty ||
        offlineDrivers.isNotEmpty ||
        lowCompletion.isNotEmpty ||
        lowOnTime.isNotEmpty;

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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(FleetRadius.pill),
                ),
                child: Text(
                  '${flaggedDrivers.length + offlineDrivers.length + lowCompletion.length + lowOnTime.length} flags',
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
                  Icon(Icons.check_circle_outline, color: AppTheme.successGreen),
                  const SizedBox(width: FleetSpacing.md),
                  Text(
                    'All drivers are performing within normal parameters',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          )
        else ...[
          if (flaggedDrivers.isNotEmpty)
            _AlertCard(
              icon: Icons.flag_rounded,
              iconColor: AppTheme.dangerRed,
              title: 'Flagged Drivers',
              subtitle: flaggedDrivers
                  .map((s) => '${s.fullName} — ${s.flagReason}')
                  .join(', '),
            ),
          if (offlineDrivers.isNotEmpty)
            _AlertCard(
              icon: Icons.cloud_off_outlined,
              iconColor: AppTheme.neutralGray500,
              title: 'Drivers Offline / No Activity Today',
              subtitle: offlineDrivers
                  .map((s) => '${s.fullName} (${s.plateNumber})')
                  .join(', '),
            ),
          if (lowCompletion.isNotEmpty)
            _AlertCard(
              icon: Icons.trending_down_rounded,
              iconColor: AppTheme.warningAmber,
              title: 'Low Completion Rate',
              subtitle: lowCompletion
                  .map((s) =>
                      '${s.fullName} — ${(s.completionRate * 100).toInt()}% completed')
                  .join(', '),
            ),
          if (lowOnTime.isNotEmpty)
            _AlertCard(
              icon: Icons.access_alarm_outlined,
              iconColor: AppTheme.warningAmber,
              title: 'Repeated Delays',
              subtitle: lowOnTime
                  .map((s) =>
                      '${s.fullName} — ${s.onTimeRate.toInt()}% on-time rate')
                  .join(', '),
            ),
        ],
      ],
    );
  }
}

class _ManagedUserY {
  const _ManagedUserY({
    required this.userId,
    required this.firstName,
    this.middleName = '',
    required this.surName,
    this.extensionName = '',
    required this.company,
    required this.role,
    required this.email,
    this.plateNumber,
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
  final String? plateNumber;
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

  factory _ManagedUserY.fromJson(Map<String, dynamic> json) {
    return _ManagedUserY(
      userId: json['userId'].toString(),
      firstName: json['firstName'] as String? ?? '',
      middleName: json['middleName'] as String? ?? '',
      surName: json['surName'] as String? ?? '',
      extensionName: json['extensionName'] as String? ?? '',
      company: json['company'] as String? ?? '',
      role: json['role'] as String? ?? '',
      email: json['email'] as String? ?? '',
      plateNumber: json['plateNumber'] as String?,
      location: _coerceString(json['location']),
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
