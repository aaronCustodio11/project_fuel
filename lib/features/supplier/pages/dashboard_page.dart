import 'package:chartify/chartify.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project_fuel/core/models/fleet_tracking.dart';
import 'package:project_fuel/core/models/maintenance.dart';
import 'package:project_fuel/core/routes/app_routes.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/services/json_reader.dart';
import 'package:project_fuel/core/services/maintenance_service.dart';
import 'package:project_fuel/core/theme/app_theme.dart';
import 'package:project_fuel/shared/widgets/action_button.dart';

class SupplierDashboard extends StatefulWidget {
  final void Function(int index)? onNavigate;
  const SupplierDashboard({super.key, this.onNavigate});

  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard>
    with SingleTickerProviderStateMixin {
  final _authService = AuthenticationService();

  AuthUser? _currentUser;
  String _selectedPeriod = 'Q2 2026';
  bool _isLoading = true;

  List<FleetTruck> _trucks = [];
  List<MaintenanceRecord> _maintenanceRecords = [];
  List<Map<String, dynamic>> _theftAlerts = [];
  List<Map<String, dynamic>> _authUsers = [];

  late final AnimationController _gradientController;
  late final Animation<double> _gradientAnim;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _gradientAnim = CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _authService.getSavedUser(),
      JsonReaderService.readListStatic('assets/mock_data/vehicles.json'),
      JsonReaderService.readListStatic('assets/mock_data/stations.json'),
      MaintenanceService().getRecords(),
      JsonReaderService.readListStatic('assets/mock_data/theft_alerts.json'),
      JsonReaderService.readListStatic('assets/mock_data/authentication.json'),
    ]);

    final user = results[0] as AuthUser?;
    final vehicles = results[1] as List<dynamic>;
    final maintenance = results[3] as List<MaintenanceRecord>;
    final theftAlerts = results[4] as List<dynamic>;
    final authUsers = results[5] as List<dynamic>;
    final supplierId = user?.supplierId;

    if (mounted) {
      setState(() {
        _currentUser = user;
        _trucks = vehicles
            .whereType<Map<String, dynamic>>()
            .map((v) => FleetTruck.fromVehicleJson(v))
            .where((t) => supplierId == null || t.supplierId == supplierId)
            .toList();
        _maintenanceRecords = maintenance;
        _theftAlerts = theftAlerts.whereType<Map<String, dynamic>>().toList();
        _authUsers = authUsers.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    }
  }

  void _showPeriodPicker() {
    final periods = ['Q1 2026', 'Q2 2026', 'Q3 2026', 'Q4 2026', '2025', '2024'];
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
            trailing: p == _selectedPeriod
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () {
              setState(() => _selectedPeriod = p);
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
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_isLoading) {
      return Center(child: LoadingAnimationWidget.staggeredDotsWave(color: scheme.primary, size: 50));
    }

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
                label: _selectedPeriod,
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
                  _buildMonitoringKpiRow(context),
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

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  Widget _buildGreeting(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hour = DateTime.now().hour;
    final isMorning = hour < 12;
    final isAfternoon = hour >= 12 && hour < 17;
    final greeting = isMorning ? 'Good Morning' : isAfternoon ? 'Good Afternoon' : 'Good Evening';
    final icon = isMorning ? Icons.wb_sunny_outlined : isAfternoon ? Icons.wb_cloudy_outlined : Icons.nightlight_outlined;

    return AnimatedBuilder(
      animation: _gradientAnim,
      builder: (context, child) {
        final begin = Alignment.lerp(
          Alignment.topLeft,
          const Alignment(-0.3, -0.3),
          _gradientAnim.value,
        )!;
        final end = Alignment.lerp(
          Alignment.bottomRight,
          const Alignment(1.2, 1.2),
          _gradientAnim.value,
        )!;

        final gradientColors = scheme.brightness == Brightness.dark
            ? [scheme.primary, scheme.primaryContainer]
            : [scheme.primary, scheme.onPrimaryContainer];

        return Container(
          padding: const EdgeInsets.all(FleetSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: begin,
              end: end,
            ),
            borderRadius: BorderRadius.circular(FleetRadius.md),
          ),
          child: child,
        );
      },
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
                  _currentUser?.fullName ?? 'Supplier',
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
                      label: _currentUser?.role ?? 'Super Admin',
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

  int get _pendingMaint => _maintenanceRecords.where((r) => r.status == MaintenanceStatus.pending).length;
  int get _inProgressMaint => _maintenanceRecords.where((r) => r.status == MaintenanceStatus.inProgress).length;
  int get _overdueMaint => _maintenanceRecords.where((r) => r.status == MaintenanceStatus.scheduled && r.scheduledDate != null && r.scheduledDate!.isBefore(DateTime.now())).length;
  int get _completedMaint => _maintenanceRecords.where((r) => r.status == MaintenanceStatus.completed).length;

  int _criticalAlerts() => _theftAlerts.where((a) {
    final sev = a['severity'] as String?;
    final resolved = a['isResolved'] as bool? ?? false;
    return (sev == 'critical' || sev == 'high') && !resolved;
  }).length;

  List<Map<String, dynamic>> _recentUnresolvedAlerts() {
    final unresolved = _theftAlerts.where((a) => (a['isResolved'] as bool? ?? false) == false).toList();
    unresolved.sort((a, b) {
      final ta = DateTime.tryParse(a['timestamp'] as String? ?? '') ?? DateTime.now();
      final tb = DateTime.tryParse(b['timestamp'] as String? ?? '') ?? DateTime.now();
      return tb.compareTo(ta);
    });
    return unresolved.take(4).toList();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _alertTypeIconColor(String type) => switch (type) {
    'fuelTheft' => AppTheme.warningAmber,
    'unauthorizedAccess' => AppTheme.dangerRed,
    'gpsTampering' => AppTheme.accentBlue,
    _ => AppTheme.brandBlue,
  };

  IconData _alertTypeIcon(String type) => switch (type) {
    'fuelTheft' => Icons.local_gas_station_outlined,
    'unauthorizedAccess' => Icons.lock_open,
    'gpsTampering' => Icons.gps_fixed,
    _ => Icons.alt_route,
  };

  String _alertSeverityLabel(String sev) => sev[0].toUpperCase() + sev.substring(1);

  Widget _buildFleetKpiRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final moving = _trucks.where((t) => t.status == TruckStatus.moving).length;
    final idle = _trucks.where((t) => t.status == TruckStatus.idle).length;
    final maint = _trucks.where((t) => t.status == TruckStatus.maintenance).length;
    final offDuty = _trucks.where((t) => t.status == TruckStatus.offDuty).length;

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
          label: 'Idle', value: '$idle',
          subtitle: 'Available', icon: Icons.pause_circle_outline,
          accentColor: AppTheme.warningAmber,
          trend: '$offDuty off duty', trendUp: true,
        )),
        const SizedBox(width: FleetSpacing.md),
        Expanded(child: _KpiCard(
          label: 'In Maintenance', value: '$maint',
          subtitle: 'In shop', icon: Icons.build_outlined,
          accentColor: AppTheme.dangerRed,
          trend: '$_overdueMaint overdue', trendUp: false,
        )),
      ],
    );
  }

  Widget _buildMonitoringKpiRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avgFuel = _trucks.fold<double>(0, (s, t) => s + (t.fuelLevel ?? 0)) / _trucks.length;
    final lowFuel = _trucks.where((t) => (t.fuelLevel ?? 0) < 0.25).length;
    final totalAlerts = _theftAlerts.length;
    final critical = _criticalAlerts();

    return Row(
      children: [
        Expanded(child: _KpiCard(
          label: 'Avg Fuel Level', value: '${(avgFuel * 100).round()}%',
          subtitle: 'Fleet average', icon: Icons.speed,
          accentColor: scheme.primary,
          trend: '$lowFuel low fuel', trendUp: lowFuel == 0,
        )),
        const SizedBox(width: FleetSpacing.md),
        Expanded(child: _KpiCard(
          label: 'Total Alerts', value: '$totalAlerts',
          subtitle: 'All time', icon: Icons.warning_amber_rounded,
          accentColor: AppTheme.dangerRed,
          trend: '$critical critical', trendUp: critical == 0,
        )),
        const SizedBox(width: FleetSpacing.md),
        Expanded(child: _KpiCard(
          label: 'Pending Maint.', value: '$_pendingMaint',
          subtitle: 'Awaiting review', icon: Icons.hourglass_empty_rounded,
          accentColor: AppTheme.warningAmber,
          trend: '$_inProgressMaint in progress', trendUp: true,
        )),
        const SizedBox(width: FleetSpacing.md),
        Expanded(child: _KpiCard(
          label: 'Completed Maint.', value: '$_completedMaint',
          subtitle: 'This period', icon: Icons.check_circle_outline,
          accentColor: AppTheme.successGreen,
          trend: '$_overdueMaint overdue', trendUp: _overdueMaint == 0,
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
    final byType = <String, int>{};
    for (final a in _theftAlerts) {
      final t = a['type'] as String? ?? 'unknown';
      byType[t] = (byType[t] ?? 0) + 1;
    }
    final typeLabels = byType.keys.map((k) {
      if (k == 'fuelTheft') return 'Fuel Theft';
      if (k == 'unauthorizedAccess') return 'Unath. Access';
      if (k == 'gpsTampering') return 'GPS Tamper';
      return 'Route Dev.';
    }).toList();
    final typeValues = byType.values.map((v) => v.toDouble()).toList();

    final bySeverity = <String, int>{};
    for (final a in _theftAlerts) {
      final s = a['severity'] as String? ?? 'low';
      bySeverity[s] = (bySeverity[s] ?? 0) + 1;
    }
    final severityColors = {
      'critical': AppTheme.dangerRed,
      'high': AppTheme.warningAmber,
      'medium': AppTheme.accentBlue,
      'low': AppTheme.neutralGray500,
    };

    final totalCost = _maintenanceRecords.fold<int>(0, (s, r) => s + r.cost.round());
    final avgCost = _maintenanceRecords.isNotEmpty ? totalCost ~/ _maintenanceRecords.length : 0;
    String fmt(int v) => '₱${v >= 1000 ? '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k' : '$v'}';

    return Row(
      children: [
        Expanded(
          child: _ChartCard(
            title: 'Alert Severity',
            subtitle: '${_theftAlerts.length} alerts',
            child: RepaintBoundary(
              child: PieChart(
                data: PieChartData(
                  sections: bySeverity.entries.where((e) => e.value > 0).map((e) => PieSection(
                    value: e.value.toDouble(),
                    label: _alertSeverityLabel(e.key),
                    color: severityColors[e.key]!,
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
          child: _ChartCard(
            title: 'Alerts by Type',
            subtitle: 'Breakdown',
            child: RepaintBoundary(
              child: BarChart(
                data: BarChartData(
                  series: [
                    BarSeries.fromValues<double>(
                      name: 'Alerts',
                      values: typeValues,
                      color: const Color(0xFFEF4444),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFF87171)],
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
        const SizedBox(width: FleetSpacing.md),
        Expanded(
          child: _ChartCard(
            title: 'Maintenance Cost',
            subtitle: '${_maintenanceRecords.length} requests',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MiniStatCard(
                      label: 'Total Spent', value: fmt(totalCost),
                      icon: Icons.account_balance_wallet_outlined, color: scheme.primary,
                    ),
                    const SizedBox(width: FleetSpacing.sm),
                    _MiniStatCard(
                      label: 'Avg per Request', value: fmt(avgCost),
                      icon: Icons.bar_chart_outlined, color: AppTheme.accentBlue,
                    ),
                  ],
                ),
                const SizedBox(height: FleetSpacing.md),
                Expanded(
                  child: _MaintenanceSummary(
                    label: 'Pending', count: _pendingMaint, color: AppTheme.warningAmber,
                  ),
                ),
                const SizedBox(height: FleetSpacing.sm),
                _MaintenanceSummary(
                  label: 'In Progress', count: _inProgressMaint, color: AppTheme.warningAmber,
                ),
                const SizedBox(height: FleetSpacing.sm),
                _MaintenanceSummary(
                  label: 'Overdue', count: _overdueMaint, color: AppTheme.dangerRed,
                ),
                const SizedBox(height: FleetSpacing.sm),
                _MaintenanceSummary(
                  label: 'Completed', count: _completedMaint, color: AppTheme.successGreen,
                ),
                const SizedBox(height: FleetSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => widget.onNavigate?.call(2),
                    child: const Text('Manage Maintenance'),
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
    final unresolved = _recentUnresolvedAlerts();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _ChartCard(
            title: 'Recent Alerts',
            subtitle: 'Latest unresolved',
            child: Column(
              children: [
                Expanded(
                  child: unresolved.isEmpty
                      ? Center(child: Text('No unresolved alerts.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant)))
                      : ListView.separated(
                          itemCount: unresolved.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final a = unresolved[i];
                            final type = a['type'] as String? ?? '';
                            final severity = a['severity'] as String? ?? 'medium';
                            final ts = DateTime.tryParse(a['timestamp'] as String? ?? '') ?? DateTime.now();
                            final vehicleId = a['vehicleId'] as String? ?? '';
                            final desc = a['description'] as String? ?? '';
                            return _AlertTile(
                              icon: _alertTypeIcon(type),
                              iconColor: _alertTypeIconColor(type),
                              title: type.replaceAllMapped(
                                RegExp(r'[A-Z]'),
                                (m) => ' ${m.group(0)}',
                              ).trim(),
                              subtitle: '$vehicleId — $desc',
                              time: _timeAgo(ts),
                              priority: _alertSeverityLabel(severity),
                            );
                          },
                        ),
                ),
                const SizedBox(height: FleetSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => widget.onNavigate?.call(5),
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
            title: 'User Overview',
            subtitle: 'People in your organization',
            child: Column(
              children: [
                Expanded(
                  child: _buildUserDonut(context),
                ),
                const SizedBox(height: FleetSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => widget.onNavigate?.call(1),
                    child: const Text('Manage Users'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserDonut(BuildContext context) {
    int countBy(String role) => _authUsers.where((u) => u['role'] == role).length;
    final managers = countBy('Manager');
    final drivers = countBy('Driver');
    final suppliers = countBy('Supplier');
    final total = managers + drivers + suppliers;

    return RepaintBoundary(
      child: PieChart(
        data: PieChartData(
          sections: [
            if (managers > 0)
              PieSection(value: managers.toDouble(), label: 'Managers', color: AppTheme.accentBlue),
            if (drivers > 0)
              PieSection(value: drivers.toDouble(), label: 'Drivers', color: AppTheme.warningAmber),
            if (suppliers > 0)
              PieSection(value: suppliers.toDouble(), label: 'Suppliers', color: AppTheme.brandBlueDark),
          ],
          holeRadius: 0.45,
          segmentGap: 2,
          showLabels: true,
          labelPosition: PieLabelPosition.outside,
          labelConnector: PieLabelConnector.elbow,
        ),
        centerWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$total', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const Text('Users', style: TextStyle(fontSize: 11)),
          ],
        ),
        tooltip: const TooltipConfig(enabled: true),
        animation: const ChartAnimation.none(),
      ),
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

class _MaintenanceSummary extends StatelessWidget {
  const _MaintenanceSummary({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: FleetSpacing.sm),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: FleetSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(FleetRadius.pill),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
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

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(FleetSpacing.sm),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(FleetRadius.sm),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: FleetSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
                Text(label, style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 10,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
