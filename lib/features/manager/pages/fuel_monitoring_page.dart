import 'package:chartify/chartify.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/services/json_reader.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

class ManagerFuelMonitoring extends StatefulWidget {
  const ManagerFuelMonitoring({super.key});

  @override
  State<ManagerFuelMonitoring> createState() => _ManagerFuelMonitoringState();
}

class _ManagerFuelMonitoringState extends State<ManagerFuelMonitoring> {
  final _authService = AuthenticationService();

  List<_StationStock> _stations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      JsonReaderService.readListStatic('assets/mock_data/stations.json'),
      _authService.getSavedUser(),
    ]);

    final rawStations = results[0] as List<dynamic>;
    final user = results[1] as AuthUser?;
    final managerId = user?.userId;

    final stations = rawStations
        .whereType<Map<String, dynamic>>()
        .map((s) => _StationStock.fromJson(s))
        .where((s) => managerId == null || s.managerId == managerId)
        .where((s) => s.capacity > 0)
        .toList();

    if (mounted) {
      setState(() {
        _stations = stations;
        _isLoading = false;
      });
    }
  }

  Color _stockColor(double pct) {
    if (pct >= 0.6) return AppTheme.successGreen;
    if (pct >= 0.3) return AppTheme.warningAmber;
    return AppTheme.dangerRed;
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

    final totalCapacity = _stations.fold<int>(0, (s, st) => s + st.capacity);
    final totalStock = _stations.fold<int>(0, (s, st) => s + st.currentStock);
    final avgStock = totalCapacity > 0 ? (totalStock / totalCapacity) : 0.0;
    final lowStockCount = _stations.where((s) => (s.currentStock / s.capacity) < 0.3).length;
    final wellStocked = _stations.where((s) => (s.currentStock / s.capacity) >= 0.6).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(FleetSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fuel Monitoring', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text('${_stations.length} station${_stations.length == 1 ? '' : 's'} assigned to you',
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: FleetSpacing.lg),
          Row(
            children: [
              Expanded(child: _KpiCard(
                label: 'Total Capacity', value: _formatVolume(totalCapacity),
                subtitle: 'Across all stations', icon: Icons.inventory,
                accentColor: scheme.primary,
              )),
              const SizedBox(width: FleetSpacing.md),
              Expanded(child: _KpiCard(
                label: 'Current Stock', value: _formatVolume(totalStock),
                subtitle: '${(avgStock * 100).round()}% filled', icon: Icons.local_gas_station,
                accentColor: AppTheme.accentBlue,
              )),
              const SizedBox(width: FleetSpacing.md),
              Expanded(child: _KpiCard(
                label: 'Well Stocked', value: wellStocked.toString(),
                subtitle: 'Above 60% capacity', icon: Icons.check_circle_outline,
                accentColor: AppTheme.successGreen,
              )),
              const SizedBox(width: FleetSpacing.md),
              Expanded(child: _KpiCard(
                label: 'Low Stock', value: '$lowStockCount',
                subtitle: 'Below 30% capacity', icon: Icons.report_problem,
                accentColor: lowStockCount > 0 ? AppTheme.dangerRed : AppTheme.successGreen,
              )),
            ],
          ),
          const SizedBox(height: FleetSpacing.lg),
          SizedBox(
            height: 280,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _ChartCard(
                    title: 'Stock Levels by Station',
                    subtitle: 'Current inventory vs capacity',
                    child: _buildStockChart(),
                  ),
                ),
                const SizedBox(width: FleetSpacing.md),
                Expanded(
                  flex: 2,
                  child: _ChartCard(
                    title: 'Capacity Distribution',
                    subtitle: 'Share of total capacity',
                    child: _buildCapacityChart(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FleetSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Station Fuel Overview', style: theme.textTheme.titleLarge),
              Text('${_stations.length} station${_stations.length == 1 ? '' : 's'}',
                  style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          ..._stations.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: FleetSpacing.md),
            child: _StationFuelCard(station: s),
          )),
        ],
      ),
    );
  }

  Widget _buildStockChart() {
    final labels = _stations.map((s) {
      final parts = s.name.split(' ');
      return parts.length > 2 ? '${parts[0]} ${parts[1]}' : s.name;
    }).toList();
    final values = _stations.map((s) => (s.currentStock / s.capacity) * 100).toList();

    return RepaintBoundary(
      child: BarChart(
        data: BarChartData(
          series: [
            BarSeries.fromValues<double>(
              name: 'Stock %',
              values: values,
              color: const Color(0xFF2E6FE0),
              gradient: LinearGradient(
                colors: [const Color(0xFF2E6FE0), const Color(0xFF5DE0FF)],
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
    );
  }

  Widget _buildCapacityChart() {
    return RepaintBoundary(
      child: PieChart(
        data: PieChartData(
          sections: _stations.map((s) {
            return PieSection(
              value: s.capacity.toDouble(),
              label: s.name.split(' ').first,
              color: _stockColor(s.currentStock / s.capacity),
            );
          }).toList(),
          holeRadius: 0.45,
          segmentGap: 2,
          showLabels: true,
          labelPosition: PieLabelPosition.outside,
          labelConnector: PieLabelConnector.elbow,
        ),
        centerWidget: Text(
          '${_stations.length}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        tooltip: const TooltipConfig(enabled: true),
        animation: const ChartAnimation.none(),
      ),
    );
  }

  String _formatVolume(int liters) {
    if (liters >= 1000) {
      return '${(liters / 1000).toStringAsFixed(1)}k L';
    }
    return '$liters L';
  }
}

class _StationStock {
  final String id;
  final String name;
  final String type;
  final int capacity;
  final int currentStock;
  final int managerId;
  final String? address;

  const _StationStock({
    required this.id,
    required this.name,
    required this.type,
    required this.capacity,
    required this.currentStock,
    required this.managerId,
    this.address,
  });

  factory _StationStock.fromJson(Map<String, dynamic> json) {
    return _StationStock(
      id: json['stationId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      currentStock: (json['currentStock'] as num?)?.toInt() ?? 0,
      managerId: json['managerId'] as int? ?? 0,
      address: json['address'] as String?,
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _KpiCard({required this.label, required this.value, required this.subtitle, required this.icon, required this.accentColor});

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
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: FleetSpacing.xs),
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

class _StationFuelCard extends StatelessWidget {
  final _StationStock station;

  const _StationFuelCard({required this.station});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pct = station.capacity > 0 ? station.currentStock / station.capacity : 0.0;
    final color = pct >= 0.6
        ? AppTheme.successGreen
        : pct >= 0.3
            ? AppTheme.warningAmber
            : AppTheme.dangerRed;

    return Container(
      padding: const EdgeInsets.all(FleetSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(FleetRadius.md),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(FleetSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(FleetRadius.sm),
                      ),
                      child: const Icon(Icons.local_gas_station_rounded, size: 20, color: AppTheme.accentBlue),
                    ),
                    const SizedBox(width: FleetSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(station.name, style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                          if (station.address != null)
                            Text(station.address!, style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FleetSpacing.md),
                Text('Fuel Stock', style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                )),
                const SizedBox(height: FleetSpacing.xs),
                Text('${_formatVolume(station.currentStock)} / ${_formatVolume(station.capacity)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: FleetSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.inventory_outlined, size: 12, color: scheme.onSurfaceVariant),
                    const SizedBox(width: FleetSpacing.xs),
                    Text('${(pct * 100).round()}% capacity used',
                        style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(FleetSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(FleetRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pct >= 0.6 ? Icons.check_circle : Icons.warning_amber_rounded,
                        size: 14,
                        color: color,
                      ),
                      const SizedBox(width: FleetSpacing.sm),
                      Flexible(
                        child: Text(
                          pct >= 0.6
                              ? 'Well stocked - No immediate action needed'
                              : pct >= 0.3
                                  ? 'Stock running low - Plan refill soon'
                                  : 'Critically low - Refill required',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: FleetSpacing.lg),
          _FuelGauge(percentage: pct, size: 90, color: color),
        ],
      ),
    );
  }

  String _formatVolume(int liters) {
    if (liters >= 1000) return '${(liters / 1000).toStringAsFixed(1)}k L';
    return '$liters L';
  }
}

class _FuelGauge extends StatelessWidget {
  final double percentage;
  final double size;
  final Color color;

  const _FuelGauge({required this.percentage, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(percentage: percentage, color: color),
        child: Center(
          child: Text(
            '${(percentage * 100).round()}%',
            style: TextStyle(
              fontSize: size * 0.2,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;

  _GaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const startAngle = -225.0;
    const sweepAngle = 270.0;
    const strokeWidth = 12.0;

    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle * (3.14159 / 180),
      sweepAngle * (3.14159 / 180),
      false,
      bgPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle * (3.14159 / 180),
      sweepAngle * percentage * (3.14159 / 180),
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) => oldDelegate.percentage != percentage;
}
