import 'dart:math' as math;
import 'package:chartify/chartify.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project_fuel/core/models/fleet_tracking.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/services/json_reader.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

class SupplierFuelMonitoring extends StatefulWidget {
  const SupplierFuelMonitoring({super.key});

  @override
  State<SupplierFuelMonitoring> createState() => _SupplierFuelMonitoringState();
}

class _SupplierFuelMonitoringState extends State<SupplierFuelMonitoring> {
  final _authService = AuthenticationService();

  List<FleetTruck> _trucks = [];
  List<_FuelStation> _stations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      JsonReaderService.readListStatic('assets/mock_data/vehicles.json'),
      JsonReaderService.readListStatic('assets/mock_data/stations.json'),
      _authService.getSavedUser(),
    ]);

    final vehicles = results[0] as List<dynamic>;
    final rawStations = results[1] as List<dynamic>;
    final user = results[2] as AuthUser?;
    final supplierId = user?.supplierId;

    if (mounted) {
      setState(() {
        _trucks = vehicles
            .whereType<Map<String, dynamic>>()
            .map((v) => FleetTruck.fromVehicleJson(v))
            .where((t) => supplierId == null || t.supplierId == supplierId)
            .toList();
        _stations = rawStations
            .whereType<Map<String, dynamic>>()
            .map((s) => _FuelStation.fromJson(s))
            .where((s) => supplierId == null || s.supplierId == supplierId)
            .toList();
        _isLoading = false;
      });
    }
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

    final trucks = _trucks;
    final gasStations = _stations.where((s) => s.type == 'gasStation').toList();
    final warehouses = _stations.where((s) => s.type == 'warehouse').toList();

    final truckAvgFuel = trucks.fold<double>(0, (s, t) => s + (t.fuelLevel ?? 0)) / math.max(trucks.length, 1);
    final lowFuelTrucks = trucks.where((t) => (t.fuelLevel ?? 0) < 0.25).length;
    final stationAvgStock = _stations.fold<double>(0, (s, st) => s + (st.capacity > 0 ? st.currentStock / st.capacity : 0)) / math.max(_stations.length, 1);
    final lowStockStations = _stations.where((s) => s.capacity > 0 && (s.currentStock / s.capacity) < 0.3).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(FleetSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fuel Monitoring', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text('Fleet fuel, gas stations, and warehouses',
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: FleetSpacing.lg),
          Row(
            children: [
              Expanded(child: _KpiCard(
                label: 'Truck Avg Fuel', value: '${(truckAvgFuel * 100).round()}%',
                subtitle: '${trucks.length} trucks', icon: Icons.local_shipping_outlined,
                accentColor: scheme.primary,
              )),
              const SizedBox(width: FleetSpacing.md),
              Expanded(child: _KpiCard(
                label: 'Low Fuel Trucks', value: '$lowFuelTrucks',
                subtitle: 'Below 25%', icon: Icons.report_problem,
                accentColor: lowFuelTrucks > 0 ? AppTheme.dangerRed : AppTheme.successGreen,
              )),
              const SizedBox(width: FleetSpacing.md),
              Expanded(child: _KpiCard(
                label: 'Station Avg Stock', value: '${(stationAvgStock * 100).round()}%',
                subtitle: '${_stations.length} stations', icon: Icons.local_gas_station,
                accentColor: AppTheme.accentBlue,
              )),
              const SizedBox(width: FleetSpacing.md),
              Expanded(child: _KpiCard(
                label: 'Low Stock Stations', value: '$lowStockStations',
                subtitle: 'Below 30%', icon: Icons.inventory,
                accentColor: lowStockStations > 0 ? AppTheme.warningAmber : AppTheme.successGreen,
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
                    title: 'Fuel Levels by Truck',
                    subtitle: '${trucks.length} trucks',
                    child: _buildTruckFuelChart(),
                  ),
                ),
                const SizedBox(width: FleetSpacing.md),
                Expanded(
                  flex: 2,
                  child: _ChartCard(
                    title: 'Station Stock Levels',
                    subtitle: '${_stations.length} stations',
                    child: _buildStationStockChart(),
                  ),
                ),
                const SizedBox(width: FleetSpacing.md),
                Expanded(
                  flex: 2,
                  child: _ChartCard(
                    title: 'Station Types',
                    subtitle: 'Gas stations vs Warehouses',
                    child: _buildStationTypeChart(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FleetSpacing.lg),
          SizedBox(
            height: 500,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _CategoryColumn(
                    title: 'Trucks',
                    count: trucks.length,
                    label: 'trucks',
                    icon: Icons.local_shipping_rounded,
                    children: trucks.map((t) => _TruckFuelCard(truck: t)).toList(),
                  ),
                ),
                const SizedBox(width: FleetSpacing.md),
                if (gasStations.isNotEmpty)
                  Expanded(
                    child: _CategoryColumn(
                      title: 'Gas Stations',
                      count: gasStations.length,
                      label: 'stations',
                      icon: Icons.local_gas_station_rounded,
                      children: gasStations.map((s) => _StationFuelCard(station: s)).toList(),
                    ),
                  ),
                const SizedBox(width: FleetSpacing.md),
                if (warehouses.isNotEmpty)
                  Expanded(
                    child: _CategoryColumn(
                      title: 'Warehouses',
                      count: warehouses.length,
                      label: 'warehouses',
                      icon: Icons.warehouse_outlined,
                      children: warehouses.map((s) => _StationFuelCard(station: s)).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTruckFuelChart() {
    final labels = _trucks.map((t) => t.name.replaceAll('Truck #', '')).toList();
    final values = _trucks.map((t) => (t.fuelLevel ?? 0) * 100).toList();

    return RepaintBoundary(
      child: BarChart(
        data: BarChartData(
          series: [
            BarSeries.fromValues<double>(
              name: 'Fuel %',
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

  Widget _buildStationStockChart() {
    final labels = _stations.map((s) => s.name.split(' ').first).toList();
    final values = _stations.map((s) => s.capacity > 0 ? (s.currentStock / s.capacity) * 100 : 0.0).toList();

    return RepaintBoundary(
      child: BarChart(
        data: BarChartData(
          series: [
            BarSeries.fromValues<double>(
              name: 'Stock %',
              values: values,
              color: const Color(0xFF1E8E4A),
              gradient: LinearGradient(
                colors: [const Color(0xFF1E8E4A), const Color(0xFF4CBB78)],
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

  Widget _buildStationTypeChart() {
    final gasCount = _stations.where((s) => s.type == 'gasStation').length;
    final warehouseCount = _stations.where((s) => s.type == 'warehouse').length;

    return RepaintBoundary(
      child: PieChart(
        data: PieChartData(
          sections: [
            PieSection(
              value: math.max(gasCount.toDouble(), 1),
              label: 'Gas Stations',
              color: AppTheme.accentBlue,
            ),
            if (warehouseCount > 0)
              PieSection(
                value: warehouseCount.toDouble(),
                label: 'Warehouses',
                color: AppTheme.brandBlue,
              ),
          ],
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
}

class _FuelStation {
  final String id;
  final String name;
  final String type;
  final int capacity;
  final int currentStock;
  final int supplierId;
  final String? address;

  const _FuelStation({
    required this.id,
    required this.name,
    required this.type,
    required this.capacity,
    required this.currentStock,
    required this.supplierId,
    this.address,
  });

  factory _FuelStation.fromJson(Map<String, dynamic> json) {
    return _FuelStation(
      id: json['stationId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      currentStock: (json['currentStock'] as num?)?.toInt() ?? 0,
      supplierId: json['supplierId'] as int? ?? 0,
      address: json['address'] as String?,
    );
  }
}

class _CategoryColumn extends StatelessWidget {
  final String title;
  final int count;
  final String label;
  final IconData icon;
  final List<Widget> children;

  const _CategoryColumn({
    required this.title,
    required this.count,
    required this.label,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(FleetRadius.md),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(FleetSpacing.lg, FleetSpacing.lg, FleetSpacing.lg, 0),
            child: Row(
              children: [
                Icon(icon, size: 20, color: scheme.primary),
                const SizedBox(width: FleetSpacing.sm),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('$count $label',
                    style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: FleetSpacing.md),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(FleetSpacing.lg, 0, FleetSpacing.lg, FleetSpacing.lg),
              children: [
                ...children,
              ],
            ),
          ),
        ],
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

class _TruckFuelCard extends StatelessWidget {
  final FleetTruck truck;

  const _TruckFuelCard({required this.truck});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pct = truck.fuelLevel ?? 0;
    final color = pct >= 0.6
        ? AppTheme.successGreen
        : pct >= 0.3
            ? AppTheme.warningAmber
            : AppTheme.dangerRed;

    return Container(
      padding: const EdgeInsets.all(FleetSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(FleetRadius.md),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(FleetRadius.sm),
                      ),
                      child: Icon(Icons.local_shipping_rounded, size: 16, color: color),
                    ),
                    const SizedBox(width: FleetSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(truck.name, style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                          Text(truck.plateNumber, style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FleetSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.speed, size: 10, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${truck.speed ?? '\u2014'} km/h',
                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: scheme.onSurfaceVariant)),
                    const SizedBox(width: FleetSpacing.md),
                    Icon(Icons.route, size: 10, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${(pct * 500).round()} km',
                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: scheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: FleetSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(FleetRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pct >= 0.25 ? Icons.check_circle : Icons.warning_amber_rounded,
                        size: 12,
                        color: color,
                      ),
                      const SizedBox(width: FleetSpacing.xs),
                      Flexible(
                        child: Text(
                          pct >= 0.25 ? 'Sufficient fuel' : 'Low fuel needed',
                          style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: color, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: FleetSpacing.md),
          _FuelGauge(percentage: pct, size: 70, color: color),
        ],
      ),
    );
  }
}

class _StationFuelCard extends StatelessWidget {
  final _FuelStation station;

  const _StationFuelCard({required this.station});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pct = station.capacity > 0 ? station.currentStock / station.capacity : 0.0;
    final isGas = station.type == 'gasStation';
    final color = pct >= 0.6
        ? AppTheme.successGreen
        : pct >= 0.3
            ? AppTheme.warningAmber
            : AppTheme.dangerRed;

    return Container(
      padding: const EdgeInsets.all(FleetSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(FleetRadius.md),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isGas ? AppTheme.accentBlue.withValues(alpha: 0.12) : AppTheme.brandBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(FleetRadius.sm),
                      ),
                      child: Icon(
                        isGas ? Icons.local_gas_station_rounded : Icons.warehouse_outlined,
                        size: 16, color: isGas ? AppTheme.accentBlue : AppTheme.brandBlue,
                      ),
                    ),
                    const SizedBox(width: FleetSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(station.name, style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                          if (station.address != null)
                            Text(station.address!, style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FleetSpacing.sm),
                Text(isGas ? 'Fuel Stock' : 'Inventory', style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10, color: scheme.onSurfaceVariant,
                )),
                const SizedBox(height: 2),
                Text('${_formatVolume(station.currentStock)} / ${_formatVolume(station.capacity)}',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.inventory_outlined, size: 10, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${(pct * 100).round()}% used',
                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: scheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: FleetSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(FleetRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pct >= 0.6 ? Icons.check_circle : Icons.warning_amber_rounded,
                        size: 12,
                        color: color,
                      ),
                      const SizedBox(width: FleetSpacing.xs),
                      Flexible(
                        child: Text(
                          pct >= 0.6
                              ? 'Well stocked'
                              : pct >= 0.3
                                  ? 'Stock running low'
                                  : 'Critically low',
                          style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: color, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: FleetSpacing.md),
          _FuelGauge(percentage: pct, size: 70, color: color),
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
      startAngle * (math.pi / 180),
      sweepAngle * (math.pi / 180),
      false,
      bgPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle * (math.pi / 180),
      sweepAngle * percentage * (math.pi / 180),
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) => oldDelegate.percentage != percentage;
}
