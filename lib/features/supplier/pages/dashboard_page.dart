import 'package:chartify/chartify.dart';
import 'package:flutter/material.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

class SupplierDashboard extends StatefulWidget {
  const SupplierDashboard({super.key});

  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  AuthUser? _currentUser;
  String _selectedPeriod = 'Q2 2026';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthenticationService().getSavedUser();
    if (mounted) setState(() => _currentUser = user);
  }

  void _showPeriodPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(FleetRadius.lg)),
      ),
      builder: (context) {
        final periods = ['Q1 2026', 'Q2 2026', 'Q3 2026', 'Q4 2026', '2025', '2024'];
        return Padding(
          padding: const EdgeInsets.all(FleetSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: FleetSpacing.lg),
              Text('Select Period', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: FleetSpacing.md),
              ...periods.map((p) => ListTile(
                title: Text(p),
                trailing: p == _selectedPeriod ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                onTap: () {
                  setState(() => _selectedPeriod = p);
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: FleetSpacing.sm),
            ],
          ),
        );
      },
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

    return Padding(
      padding: const EdgeInsets.all(FleetSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dashboard', style: theme.textTheme.headlineLarge),
              InkWell(
                onTap: _showPeriodPicker,
                borderRadius: BorderRadius.circular(FleetRadius.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FleetSpacing.md,
                    vertical: FleetSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(FleetRadius.sm),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: FleetSpacing.sm),
                      Text(
                        _selectedPeriod,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: FleetSpacing.xs),
                      Icon(Icons.arrow_drop_down, size: 16, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
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
                  _buildKpiRow(context),
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
          Container(
            padding: const EdgeInsets.all(FleetSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(FleetRadius.sm),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
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
        ],
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(child: _KpiCard(
          label: 'Total Fleet',
          value: '128',
          subtitle: '12 in maintenance',
          icon: Icons.local_shipping_outlined,
          accentColor: scheme.primary,
          trend: '+3 this month',
          trendUp: true,
        )),
        const SizedBox(width: FleetSpacing.md),
        Expanded(child: _KpiCard(
          label: 'Active Drivers',
          value: '96',
          subtitle: '32 off duty',
          icon: Icons.person_outline,
          accentColor: AppTheme.accentBlue,
          trend: '85% availability',
          trendUp: true,
        )),
        const SizedBox(width: FleetSpacing.md),
        Expanded(child: _KpiCard(
          label: 'Fuel Consumption',
          value: '45.2K L',
          subtitle: 'This month',
          icon: Icons.local_gas_station_outlined,
          accentColor: AppTheme.warningAmber,
          trend: '-8% vs last month',
          trendUp: false,
        )),
        const SizedBox(width: FleetSpacing.md),
        Expanded(child: _KpiCard(
          label: 'Open Tickets',
          value: '18',
          subtitle: '7 urgent',
          icon: Icons.build_outlined,
          accentColor: AppTheme.dangerRed,
          trend: '3 escalated',
          trendUp: false,
        )),
      ],
    );
  }

  Widget _buildChartsRow1(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _ChartCard(
            title: 'Fuel Consumption Trend',
            subtitle: 'Monthly fuel usage in litres',
            child: RepaintBoundary(
              child: LineChart(
                data: LineChartData(
                  series: [
                    LineSeries(
                      name: 'Diesel',
                      data: const [
                        DataPoint(x: 0, y: 38),
                        DataPoint(x: 1, y: 42),
                        DataPoint(x: 2, y: 40),
                        DataPoint(x: 3, y: 45),
                        DataPoint(x: 4, y: 43),
                        DataPoint(x: 5, y: 47),
                        DataPoint(x: 6, y: 44),
                        DataPoint(x: 7, y: 48),
                      ],
                      color: const Color(0xFF6366F1),
                      curved: true,
                      fillArea: true,
                      areaOpacity: 0.15,
                      showMarkers: true,
                      strokeWidth: 2.5,
                    ),
                    LineSeries(
                      name: 'Gasoline',
                      data: const [
                        DataPoint(x: 0, y: 22),
                        DataPoint(x: 1, y: 25),
                        DataPoint(x: 2, y: 23),
                        DataPoint(x: 3, y: 28),
                        DataPoint(x: 4, y: 26),
                        DataPoint(x: 5, y: 30),
                        DataPoint(x: 6, y: 27),
                        DataPoint(x: 7, y: 32),
                      ],
                      color: const Color(0xFFF59E0B),
                      curved: true,
                      fillArea: true,
                      areaOpacity: 0.15,
                      showMarkers: true,
                      strokeWidth: 2.5,
                    ),
                  ],
                  xAxis: const AxisConfig(
                    label: 'Month',
                    type: AxisType.category,
                  ),
                  yAxis: const AxisConfig(label: 'Litres (K)', min: 0),
                  showLegend: true,
                  crosshairEnabled: true,
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
            title: 'Fleet Status',
            subtitle: 'Current vehicle states',
            child: RepaintBoundary(
              child: BarChart(
                data: BarChartData(
                  series: [
                    BarSeries.fromValues<double>(
                      name: 'Vehicles',
                      values: const [52, 28, 18, 30],
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
                  yAxis: const BarYAxisConfig(min: 0),
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
    return Row(
      children: [
        Expanded(
          child: _ChartCard(
            title: 'Fleet Composition',
            subtitle: 'By fuel type',
            child: RepaintBoundary(
              child: PieChart(
                data: PieChartData(
                  sections: [
                    PieSection(
                      value: 58,
                      label: 'Diesel',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      shadowElevation: 4,
                    ),
                    const PieSection(
                      value: 25,
                      label: 'Gasoline',
                      color: Color(0xFFF59E0B),
                    ),
                    const PieSection(
                      value: 12,
                      label: 'Electric',
                      color: Color(0xFF10B981),
                    ),
                    const PieSection(
                      value: 5,
                      label: 'Hybrid',
                      color: Color(0xFFEC4899),
                    ),
                  ],
                  holeRadius: 0.45,
                  segmentGap: 2,
                  cornerRadius: 4,
                  enableShadows: true,
                  showLabels: true,
                  labelPosition: PieLabelPosition.outside,
                  labelConnector: PieLabelConnector.elbow,
                ),
                centerWidget: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('128', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    Text('Total', style: TextStyle(fontSize: 11)),
                  ],
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
            title: 'Revenue vs Operating Costs',
            subtitle: 'Monthly overview',
            child: RepaintBoundary(
              child: AreaChart(
                data: AreaChartData(
                  series: [
                    AreaSeries(
                      name: 'Revenue',
                      data: const [
                        DataPoint(x: 0, y: 180),
                        DataPoint(x: 1, y: 220),
                        DataPoint(x: 2, y: 195),
                        DataPoint(x: 3, y: 250),
                        DataPoint(x: 4, y: 230),
                        DataPoint(x: 5, y: 270),
                        DataPoint(x: 6, y: 245),
                        DataPoint(x: 7, y: 290),
                      ],
                      color: const Color(0xFF22C55E),
                      fillOpacity: 0.2,
                    ),
                    AreaSeries(
                      name: 'Costs',
                      data: const [
                        DataPoint(x: 0, y: 140),
                        DataPoint(x: 1, y: 160),
                        DataPoint(x: 2, y: 155),
                        DataPoint(x: 3, y: 180),
                        DataPoint(x: 4, y: 170),
                        DataPoint(x: 5, y: 195),
                        DataPoint(x: 6, y: 185),
                        DataPoint(x: 7, y: 210),
                      ],
                      color: const Color(0xFFEF4444),
                      fillOpacity: 0.2,
                    ),
                  ],
                  stacked: false,
                ),
                animation: const ChartAnimation.none(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _ChartCard(
            title: 'Recent Alerts & Theft Detection',
            subtitle: 'Last 7 days',
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _AlertTile(
                          icon: Icons.warning_amber_rounded,
                          iconColor: AppTheme.warningAmber,
                          title: 'Unauthorized fuel access',
                          subtitle: 'Truck #FL-2042 - 30L discrepancy',
                          time: '2 hours ago',
                          priority: 'High',
                        ),
                        const Divider(height: 1),
                        _AlertTile(
                          icon: Icons.gps_fixed,
                          iconColor: AppTheme.dangerRed,
                          title: 'GPS signal loss',
                          subtitle: 'Truck #FL-1078 - last ping 4h ago',
                          time: '4 hours ago',
                          priority: 'Critical',
                        ),
                        const Divider(height: 1),
                        _AlertTile(
                          icon: Icons.speed,
                          iconColor: AppTheme.accentBlue,
                          title: 'Route deviation detected',
                          subtitle: 'Truck #FL-3091 - 15km off route',
                          time: '6 hours ago',
                          priority: 'Medium',
                        ),
                        const Divider(height: 1),
                        _AlertTile(
                          icon: Icons.local_gas_station_outlined,
                          iconColor: AppTheme.warningAmber,
                          title: 'Fuel theft attempt',
                          subtitle: 'Station #ST-005 - after hours refuel',
                          time: '1 day ago',
                          priority: 'High',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: FleetSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
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
            title: 'Maintenance Overview',
            subtitle: 'Pending & in-progress',
            child: Column(
              children: [
                _MaintenanceSummary(
                  label: 'Scheduled',
                  count: 8,
                  color: AppTheme.accentBlue,
                ),
                const SizedBox(height: FleetSpacing.sm),
                _MaintenanceSummary(
                  label: 'In Progress',
                  count: 5,
                  color: AppTheme.warningAmber,
                ),
                const SizedBox(height: FleetSpacing.sm),
                _MaintenanceSummary(
                  label: 'Overdue',
                  count: 3,
                  color: AppTheme.dangerRed,
                ),
                const SizedBox(height: FleetSpacing.sm),
                _MaintenanceSummary(
                  label: 'Completed this month',
                  count: 14,
                  color: AppTheme.successGreen,
                ),
                const SizedBox(height: FleetSpacing.xl),
                Row(
                  children: [
                    _MiniStatCard(
                      label: 'Avg. Repair Time',
                      value: '2.4 days',
                      icon: Icons.timer_outlined,
                      color: AppTheme.accentBlue,
                    ),
                    const SizedBox(width: FleetSpacing.sm),
                    _MiniStatCard(
                      label: 'Parts Cost',
                      value: '\$8.2K',
                      icon: Icons.monetization_on_outlined,
                      color: AppTheme.warningAmber,
                    ),
                  ],
                ),
                const SizedBox(height: FleetSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
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
