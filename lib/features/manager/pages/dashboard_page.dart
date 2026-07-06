import 'dart:math' as math;
import 'package:chartify/chartify.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project_fuel/core/models/fleet_tracking.dart';
import 'package:project_fuel/core/routes/app_routes.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/services/json_reader.dart';
import 'package:project_fuel/core/theme/app_theme.dart';
import 'package:project_fuel/shared/widgets/action_button.dart';

class ManagerDashboard extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const ManagerDashboard({super.key, this.onNavigate});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final _authService = AuthenticationService();

  AuthUser? _currentUser;
  bool _isLoading = true;

  List<FleetTruck> _trucks = [];
  List<Map<String, dynamic>> _stations = [];
  List<Map<String, dynamic>> _theftAlerts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _authService.getSavedUser(),
      JsonReaderService.readListStatic('assets/mock_data/vehicles.json'),
      JsonReaderService.readListStatic('assets/mock_data/stations.json'),
      JsonReaderService.readListStatic('assets/mock_data/theft_alerts.json'),
    ]);

    final user = results[0] as AuthUser?;
    final vehicles = results[1] as List<dynamic>;
    final rawStations = results[2] as List<dynamic>;
    final theftAlerts = results[3] as List<dynamic>;
    final supplierId = user?.supplierId;
    final managerId = user?.userId;

    if (mounted) {
      setState(() {
        _currentUser = user;
        _trucks = vehicles
            .whereType<Map<String, dynamic>>()
            .map((v) => FleetTruck.fromVehicleJson(v))
            .where((t) => supplierId == null || t.supplierId == supplierId)
            .toList();
        _stations = rawStations
            .whereType<Map<String, dynamic>>()
            .where((s) => managerId == null || s['managerId'] == managerId)
            .where((s) => ((s['capacity'] as num?)?.toInt() ?? 0) > 0)
            .toList();
        _theftAlerts = theftAlerts.whereType<Map<String, dynamic>>().toList();
        _isLoading = false;
      });
    }
  }

  void _showPeriodPicker() {
    final periods = ['Q2 2026', 'Q3 2026', 'Q4 2026', '2026', '2025'];
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FleetRadius.md),
        ),
        title: const Text('Select Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: periods.map((p) => ListTile(
            title: Text(p),
            trailing: p == 'Q2 2026'
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () {
              Navigator.pop(dialogContext);
            },
          )).toList(),
        ),
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

    return Padding(
      padding: const EdgeInsets.all(FleetSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dashboard', style: theme.textTheme.headlineLarge),
              ActionButton(
                icon: Icons.calendar_today,
                label: 'Q2 2026',
                color: scheme.primary,
                onTap: _showPeriodPicker,
              ),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildGreeting(context),
                  const SizedBox(height: FleetSpacing.lg),
                  _buildFleetKpiRow(context),
                  const SizedBox(height: FleetSpacing.xl),
                  _buildStationKpiRow(context),
                  const SizedBox(height: FleetSpacing.xl),
                  SizedBox(height: 340, child: _buildChartsRow1(context)),
                  const SizedBox(height: FleetSpacing.xl),
                  SizedBox(height: 340, child: _buildChartsRow2(context)),
                  const SizedBox(height: FleetSpacing.xl),
                  SizedBox(height: 340, child: _buildBottomRow(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hour = DateTime.now().hour;
    final isMorning = hour < 12;
    final isAfternoon = hour >= 12 && hour < 17;
    final greeting = isMorning ? 'Good Morning' : isAfternoon ? 'Good Afternoon' : 'Good Evening';
    final icon = isMorning ? Icons.wb_sunny_outlined : isAfternoon ? Icons.wb_cloudy_outlined : Icons.nightlight_outlined;

    return Container(
      padding: const EdgeInsets.all(FleetSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(FleetRadius.md),
      ),
      child: Row(
        children: [
          _AnimatedWeatherIcon(icon: icon),
          const SizedBox(width: FleetSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentUser?.fullName ?? 'Manager',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: FleetSpacing.xs),
                Wrap(
                  spacing: FleetSpacing.sm,
                  runSpacing: FleetSpacing.xs,
                  children: [
                    _TagBadge(
                      label: _currentUser?.role ?? 'Manager',
                      color: scheme.onPrimary.withValues(alpha: 0.2),
                    ),
                    _TagBadge(
                      label: _currentUser?.company ?? 'FleetSense',
                      color: scheme.onPrimary.withValues(alpha: 0.2),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ActionButton(
            icon: Icons.person_outline,
            label: 'Go to Account',
            color: Colors.white,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetKpiRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final moving = _trucks.where((t) => t.status == TruckStatus.moving).length;
    final idle = _trucks.where((t) => t.status == TruckStatus.idle).length;
    final maint = _trucks.where((t) => t.status == TruckStatus.maintenance).length;
    final offDuty = _trucks.where((t) => t.status == TruckStatus.offDuty).length;
    final avgFuel = _trucks.fold<double>(0, (s, t) => s + (t.fuelLevel ?? 0)) / math.max(_trucks.length, 1);
    final lowFuel = _trucks.where((t) => (t.fuelLevel ?? 0) < 0.25).length;

    return Row(
      children: [
        Expanded(child: _KpiCard(
          label: 'Total Trucks', value: '${_trucks.length}',
          subtitle: 'In fleet', icon: Icons.local_shipping_outlined,
          accentColor: scheme.primary,
          trend: '$moving moving', trendUp: true,
        )),
        const SizedBox(width: FleetSpacing.md),
        Expanded(child: _KpiCard(
          label: 'Moving', value: '$moving',
          subtitle: 'On route', icon: Icons.arrow_forward,
          accentColor: AppTheme.successGreen,
          trend: '$idle idle', trendUp: true,
        )),
        const SizedBox(width: FleetSpacing.md),
        Expanded(child: _KpiCard(
          label: 'Avg Fuel', value: '${(avgFuel * 100).round()}%',
          subtitle: 'Fleet average', icon: Icons.speed,
          accentColor: AppTheme.accentBlue,
          trend: '$lowFuel low fuel', trendUp: lowFuel == 0,
        )),
        const SizedBox(width: FleetSpacing.md),
        Expanded(child: _KpiCard(
          label: 'In Maintenance', value: '$maint',
          subtitle: 'In shop', icon: Icons.build_outlined,
          accentColor: AppTheme.dangerRed,
          trend: '$offDuty off duty', trendUp: false,
        )),
      ],
    );
  }

  Widget _buildStationKpiRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalCapacity = _stations.fold<int>(0, (s, st) => s + ((st['capacity'] as num?)?.toInt() ?? 0));
    final totalStock = _stations.fold<int>(0, (s, st) => s + ((st['currentStock'] as num?)?.toInt() ?? 0));
    final avgStock = totalCapacity > 0 ? totalStock / totalCapacity : 0.0;
    final lowStock = _stations.where((s) {
      final cap = (s['capacity'] as num?)?.toInt() ?? 0;
      final stock = (s['currentStock'] as num?)?.toInt() ?? 0;
      return cap > 0 && (stock / cap) < 0.3;
    }).length;
    final wellStocked = _stations.where((s) {
      final cap = (s['capacity'] as num?)?.toInt() ?? 0;
      final stock = (s['currentStock'] as num?)?.toInt() ?? 0;
      return cap > 0 && (stock / cap) >= 0.6;
    }).length;

    String fmt(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k L' : '$v L';

    return Row(
      children: [
        Expanded(child: _KpiCard(
          label: 'Total Capacity', value: fmt(totalCapacity),
          subtitle: '${_stations.length} stations', icon: Icons.inventory,
          accentColor: scheme.primary,
          trend: '${(avgStock * 100).round()}% filled', trendUp: true,
        )),
        const SizedBox(width: FleetSpacing.md),
        Expanded(child: _KpiCard(
          label: 'Current Stock', value: fmt(totalStock),
          subtitle: 'Total fuel on hand', icon: Icons.local_gas_station,
          accentColor: AppTheme.accentBlue,
          trend: '$wellStocked well stocked', trendUp: true,
        )),
        const SizedBox(width: FleetSpacing.md),
        Expanded(child: _KpiCard(
          label: 'Well Stocked', value: '$wellStocked',
          subtitle: 'Above 60%', icon: Icons.check_circle_outline,
          accentColor: AppTheme.successGreen,
          trend: '${_stations.length - wellStocked - lowStock} moderate', trendUp: true,
        )),
        const SizedBox(width: FleetSpacing.md),
        Expanded(child: _KpiCard(
          label: 'Low Stock', value: '$lowStock',
          subtitle: 'Below 30%', icon: Icons.report_problem,
          accentColor: lowStock > 0 ? AppTheme.dangerRed : AppTheme.successGreen,
          trend: 'Needs attention', trendUp: lowStock == 0,
        )),
      ],
    );
  }

  Widget _buildChartsRow1(BuildContext context) {
    final moving = _trucks.where((t) => t.status == TruckStatus.moving).length;
    final idle = _trucks.where((t) => t.status == TruckStatus.idle).length;
    final maint = _trucks.where((t) => t.status == TruckStatus.maintenance).length;
    final offDuty = _trucks.where((t) => t.status == TruckStatus.offDuty).length;

    final labels = _trucks.map((t) => t.name.replaceAll('Truck #', '')).toList();
    final fuelValues = _trucks.map((t) => (t.fuelLevel ?? 0) * 100).toList();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _ChartCard(
            title: 'Fleet Status',
            subtitle: '${_trucks.length} trucks',
            child: RepaintBoundary(
              child: BarChart(
                data: BarChartData(
                  series: [
                    BarSeries.fromValues<double>(
                      name: 'Trucks',
                      values: [moving.toDouble(), idle.toDouble(), maint.toDouble(), offDuty.toDouble()],
                      color: const Color(0xFF6366F1),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ],
                  xAxis: const BarXAxisConfig(
                    categories: ['Moving', 'Idle', 'Maintenance', 'Off Duty'],
                  ),
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
        const SizedBox(width: FleetSpacing.md),
        Expanded(
          flex: 2,
          child: _ChartCard(
            title: 'Truck Fuel Levels',
            subtitle: '${_trucks.length} trucks',
            child: RepaintBoundary(
              child: BarChart(
                data: BarChartData(
                  series: [
                    BarSeries.fromValues<double>(
                      name: 'Fuel %',
                      values: fuelValues,
                      color: const Color(0xFF2E6FE0),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E6FE0), Color(0xFF5DE0FF)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ],
                  xAxis: BarXAxisConfig(categories: labels),
                  yAxis: const BarYAxisConfig(min: 0, max: 100),
                  grouping: BarGrouping.grouped,
                  direction: BarDirection.vertical,
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

  Widget _buildChartsRow2(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stationNames = _stations.map((s) => (s['name'] as String? ?? '').split(' ').first).toList();
    final stockValues = _stations.map((s) {
      final cap = (s['capacity'] as num?)?.toInt() ?? 0;
      final stock = (s['currentStock'] as num?)?.toInt() ?? 0;
      return cap > 0 ? (stock / cap) * 100 : 0.0;
    }).toList();

    final byStatus = <String, int>{};
    for (final a in _theftAlerts) {
      final resolved = a['isResolved'] as bool? ?? false;
      final status = resolved ? 'Resolved' : 'Active';
      byStatus[status] = (byStatus[status] ?? 0) + 1;
    }
    final statusColors = {
      'Active': AppTheme.dangerRed,
      'Resolved': AppTheme.successGreen,
    };

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _ChartCard(
            title: 'Station Stock Levels',
            subtitle: '${_stations.length} stations',
            child: RepaintBoundary(
              child: BarChart(
                data: BarChartData(
                  series: [
                    BarSeries.fromValues<double>(
                      name: 'Stock %',
                      values: stockValues,
                      color: const Color(0xFF1E8E4A),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF34D399)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ],
                  xAxis: BarXAxisConfig(categories: stationNames),
                  yAxis: const BarYAxisConfig(min: 0, max: 100),
                  grouping: BarGrouping.grouped,
                  direction: BarDirection.vertical,
                ),
                tooltip: const TooltipConfig(enabled: true),
                animation: const ChartAnimation.none(),
              ),
            ),
          ),
        ),
        const SizedBox(width: FleetSpacing.md),
        Expanded(
          flex: 2,
          child: _ChartCard(
            title: 'Alert Status',
            subtitle: '${_theftAlerts.length} alerts',
            child: RepaintBoundary(
              child: PieChart(
                data: PieChartData(
                  sections: byStatus.entries.where((e) => e.value > 0).map((e) => PieSection(
                    value: e.value.toDouble(),
                    label: e.key,
                    color: statusColors[e.key]!,
                  )).toList(),
                  holeRadius: 0.45,
                  segmentGap: 2,
                  showLabels: true,
                  labelPosition: PieLabelPosition.outside,
                  labelConnector: PieLabelConnector.elbow,
                ),
                centerWidget: Text('${_theftAlerts.length}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                tooltip: const TooltipConfig(enabled: true),
                animation: const ChartAnimation.none(),
              ),
            ),
          ),
        ),
        const SizedBox(width: FleetSpacing.md),
        Expanded(
          flex: 2,
          child: _ChartCard(
            title: 'Station Summary',
            subtitle: 'Stock health',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StationSummary(
                  label: 'Well Stocked',
                  count: _stations.where((s) {
                    final cap = (s['capacity'] as num?)?.toInt() ?? 0;
                    final stock = (s['currentStock'] as num?)?.toInt() ?? 0;
                    return cap > 0 && (stock / cap) >= 0.6;
                  }).length,
                  color: AppTheme.successGreen,
                ),
                const SizedBox(height: FleetSpacing.sm),
                _StationSummary(
                  label: 'Moderate',
                  count: _stations.where((s) {
                    final cap = (s['capacity'] as num?)?.toInt() ?? 0;
                    final stock = (s['currentStock'] as num?)?.toInt() ?? 0;
                    return cap > 0 && (stock / cap) >= 0.3 && (stock / cap) < 0.6;
                  }).length,
                  color: AppTheme.warningAmber,
                ),
                const SizedBox(height: FleetSpacing.sm),
                _StationSummary(
                  label: 'Low Stock',
                  count: _stations.where((s) {
                    final cap = (s['capacity'] as num?)?.toInt() ?? 0;
                    final stock = (s['currentStock'] as num?)?.toInt() ?? 0;
                    return cap > 0 && (stock / cap) < 0.3;
                  }).length,
                  color: AppTheme.dangerRed,
                ),
                const SizedBox(height: FleetSpacing.md),
                Expanded(child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(FleetSpacing.md),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(FleetRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_outlined, size: 14, color: scheme.primary),
                      const SizedBox(width: FleetSpacing.sm),
                      Text('Total Capacity',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant)),
                      const Spacer(),
                      Text(
                        _stations.fold<int>(0, (s, st) => s + ((st['capacity'] as num?)?.toInt() ?? 0)) >= 1000
                            ? '${(_stations.fold<int>(0, (s, st) => s + ((st['capacity'] as num?)?.toInt() ?? 0)) / 1000).toStringAsFixed(1)}k L'
                            : '${_stations.fold<int>(0, (s, st) => s + ((st['capacity'] as num?)?.toInt() ?? 0))} L',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: FleetSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => widget.onNavigate?.call(1),
                    child: const Text('View Stations'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    final unresolved = _theftAlerts.where((a) => (a['isResolved'] as bool? ?? false) == false).toList();
    unresolved.sort((a, b) {
      final ta = DateTime.tryParse(a['timestamp'] as String? ?? '') ?? DateTime.now();
      final tb = DateTime.tryParse(b['timestamp'] as String? ?? '') ?? DateTime.now();
      return tb.compareTo(ta);
    });
    final recent = unresolved.take(4).toList();

    String timeAgo(DateTime dt) {
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _ChartCard(
            title: 'Recent Alerts',
            subtitle: 'Latest unresolved theft alerts',
            child: Column(
              children: [
                Expanded(
                  child: recent.isEmpty
                      ? Center(child: Text('No unresolved alerts.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant)))
                      : ListView.separated(
                          itemCount: recent.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final a = recent[i];
                            final type = a['type'] as String? ?? '';
                            final sv = a['severity'] as String? ?? 'medium';
                            final ts = DateTime.tryParse(a['timestamp'] as String? ?? '') ?? DateTime.now();
                            final vid = a['vehicleId'] as String? ?? '';
                            final desc = a['description'] as String? ?? '';
                            return _AlertTile(
                              icon: type == 'fuelTheft'
                                  ? Icons.local_gas_station_outlined
                                  : type == 'unauthorizedAccess'
                                      ? Icons.lock_open
                                      : type == 'gpsTampering'
                                          ? Icons.gps_fixed
                                          : Icons.alt_route,
                              iconColor: type == 'fuelTheft'
                                  ? AppTheme.warningAmber
                                  : type == 'unauthorizedAccess'
                                      ? AppTheme.dangerRed
                                      : type == 'gpsTampering'
                                          ? AppTheme.accentBlue
                                          : AppTheme.brandBlue,
                              title: type.replaceAllMapped(
                                RegExp(r'[A-Z]'),
                                (m) => ' ${m.group(0)}',
                              ).trim(),
                              subtitle: '$vid \u2014 $desc',
                              time: timeAgo(ts),
                              priority: sv[0].toUpperCase() + sv.substring(1),
                            );
                          },
                        ),
                ),
                const SizedBox(height: FleetSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => widget.onNavigate?.call(3),
                    child: const Text('View All Alerts'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: FleetSpacing.md),
        Expanded(
          flex: 2,
          child: _ChartCard(
            title: 'Quick Actions',
            subtitle: 'Navigate to pages',
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _QuickActionTile(
                          icon: Icons.local_gas_station_outlined,
                          label: 'Fuel Monitoring',
                          count: _stations.length,
                          color: AppTheme.accentBlue,
                          onTap: () => widget.onNavigate?.call(1),
                        ),
                        const SizedBox(height: FleetSpacing.md),
                        _QuickActionTile(
                          icon: Icons.map_outlined,
                          label: 'Fleet Tracking',
                          count: _trucks.length,
                          color: AppTheme.successGreen,
                          onTap: () => widget.onNavigate?.call(2),
                        ),
                        const SizedBox(height: FleetSpacing.md),
                        _QuickActionTile(
                          icon: Icons.shield_outlined,
                          label: 'Report Incident',
                          count: _theftAlerts.length,
                          color: AppTheme.dangerRed,
                          onTap: () => widget.onNavigate?.call(3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(FleetRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
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

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.priority,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final String priority;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final priorityColor = switch (priority) {
      'Critical' => AppTheme.dangerRed,
      'High' => AppTheme.warningAmber,
      _ => AppTheme.accentBlue,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FleetSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(FleetSpacing.sm),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(FleetRadius.sm),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: FleetSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: FleetSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(FleetRadius.pill),
                      ),
                      child: Text(priority, style: theme.textTheme.labelSmall?.copyWith(
                        color: priorityColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(child: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ))),
                    Text(time, style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StationSummary extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StationSummary({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: FleetSpacing.sm),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.sm, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(FleetRadius.pill),
          ),
          child: Text('$count', style: TextStyle(
            color: color, fontWeight: FontWeight.w700, fontSize: 12,
          )),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FleetRadius.sm),
      child: Container(
        padding: const EdgeInsets.all(FleetSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(FleetRadius.sm),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(FleetSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(FleetRadius.sm),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: FleetSpacing.md),
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(FleetRadius.pill),
              ),
              child: Text('$count', style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 12,
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedWeatherIcon extends StatefulWidget {
  final IconData icon;
  const _AnimatedWeatherIcon({required this.icon});

  @override
  State<_AnimatedWeatherIcon> createState() => _AnimatedWeatherIconState();
}

class _AnimatedWeatherIconState extends State<_AnimatedWeatherIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSun = widget.icon == Icons.wb_sunny_outlined;
    final isCloud = widget.icon == Icons.wb_cloudy_outlined;

    return Container(
      padding: const EdgeInsets.all(FleetSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(FleetRadius.sm),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          double dx = 0, dy = 0;
          double scale = 1.0;

          if (isSun) {
            scale = 1.0 + _animation.value * 0.06;
          } else if (isCloud) {
            dx = (_animation.value - 0.5) * 4;
          } else {
            dy = (_animation.value - 0.5) * -4;
          }

          return Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          );
        },
        child: Icon(widget.icon, color: Colors.white, size: 28),
      ),
    );
  }
}
