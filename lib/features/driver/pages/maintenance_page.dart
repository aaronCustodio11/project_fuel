import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project_fuel/core/models/maintenance.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/services/deliveries.dart';
import 'package:project_fuel/core/services/maintenance_service.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

class VehicleMaintenancePage extends StatefulWidget {
  const VehicleMaintenancePage({super.key});

  @override
  State<VehicleMaintenancePage> createState() => _VehicleMaintenancePageState();
}

class _VehicleMaintenancePageState extends State<VehicleMaintenancePage> {
  final AuthenticationService _authService = AuthenticationService();
  final DeliveryService _deliveryService = DeliveryService();

  bool _isLoading = true;
  TruckModel? _truck;
  AuthUser? _user;
  List<MaintenanceRecord> _maintenanceRecords = [];
  int _nextMntId = 15;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _user = await _authService.getSavedUser();
    if (_user != null) {
      final results = await Future.wait([
        _deliveryService.getTruckForDriver(_user!.userId),
        MaintenanceService().getRecords(),
      ]);
      _truck = results[0] as TruckModel?;
      final allRecords = results[1] as List<MaintenanceRecord>;
      if (_truck != null) {
        _maintenanceRecords = allRecords.where((r) => r.vehicleId == _truck!.truckId).toList();
      }
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _showSubmitRequestDialog({MaintenanceRecord? existingRecord}) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isEditing = existingRecord != null;
    final wasRejected = isEditing && existingRecord.status == MaintenanceStatus.cancelled;

    final typeCtrl = TextEditingController(text: existingRecord?.type ?? '');
    final descCtrl = TextEditingController(text: existingRecord?.description ?? '');
    final priorityNotifier = ValueNotifier<MaintenancePriority>(
        existingRecord?.priority ?? MaintenancePriority.medium);
    final dateNotifier = ValueNotifier<DateTime?>(existingRecord?.preferredDate);

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FleetRadius.lg)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(FleetSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wasRejected ? 'Resubmit Maintenance Request'
                        : isEditing ? 'Edit Maintenance Request'
                        : 'Submit Maintenance Request',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: FleetSpacing.xs),
                  Text(_truck?.plateNumber ?? '', style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  )),
                  if (wasRejected && existingRecord.rejectionReason != null) ...[
                    const SizedBox(height: FleetSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(FleetSpacing.md),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(FleetRadius.sm),
                        border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: AppTheme.dangerRed),
                          const SizedBox(width: FleetSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rejection reason:',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        color: AppTheme.dangerRed, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(existingRecord.rejectionReason!,
                                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.dangerRed)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: FleetSpacing.lg),
                  TextField(
                    controller: typeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Issue Type',
                      hintText: 'e.g. Brake Inspection, Oil Change',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(FleetRadius.sm)),
                    ),
                  ),
                  const SizedBox(height: FleetSpacing.md),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the issue in detail...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(FleetRadius.sm)),
                    ),
                  ),
                  const SizedBox(height: FleetSpacing.md),
                  ValueListenableBuilder<MaintenancePriority>(
                    valueListenable: priorityNotifier,
                    builder: (_, p, _) => DropdownButtonFormField<MaintenancePriority>(
                      initialValue: p,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(FleetRadius.sm)),
                      ),
                      items: MaintenancePriority.values.map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(v.label),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) priorityNotifier.value = v;
                      },
                    ),
                  ),
                  const SizedBox(height: FleetSpacing.md),
                  ValueListenableBuilder<DateTime?>(
                    valueListenable: dateNotifier,
                    builder: (_, d, _) => InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: d ?? DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 180)),
                        );
                        if (picked != null) dateNotifier.value = picked;
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Preferred Schedule',
                          hintText: 'Tap to select date',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(FleetRadius.sm)),
                          suffixIcon: const Icon(Icons.calendar_today, size: 18),
                        ),
                        child: Text(
                          d != null ? '${d.month}/${d.day}/${d.year}' : '',
                          style: theme.textTheme.bodyMedium,
                        ),
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
                          final type = typeCtrl.text.trim();
                          final desc = descCtrl.text.trim();
                          if (type.isEmpty || desc.isEmpty) return;
                          Navigator.pop(ctx, {
                            'type': type,
                            'description': desc,
                            'priority': priorityNotifier.value,
                            'preferredDate': dateNotifier.value,
                          });
                        },
                        child: Text(wasRejected ? 'Resubmit'
                            : isEditing ? 'Save Changes'
                            : 'Submit Request'),
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

    if (isEditing) {
      setState(() {
        final idx = _maintenanceRecords.indexWhere((r) => r.id == existingRecord.id);
        if (idx != -1) {
          _maintenanceRecords[idx] = MaintenanceRecord(
            id: existingRecord.id,
            vehicleId: existingRecord.vehicleId,
            vehicleName: existingRecord.vehicleName,
            type: result['type'] as String,
            description: result['description'] as String,
            status: wasRejected ? MaintenanceStatus.pending : existingRecord.status,
            priority: result['priority'] as MaintenancePriority,
            preferredDate: result['preferredDate'] as DateTime?,
            createdAt: existingRecord.createdAt,
            rejectionReason: wasRejected ? null : existingRecord.rejectionReason,
          );
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasRejected ? 'Request resubmitted' : 'Request updated'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      final now = DateTime.now();
      final newRecord = MaintenanceRecord(
        id: 'MNT-${_nextMntId.toString().padLeft(3, '0')}',
        vehicleId: _truck!.truckId,
        vehicleName: _truck!.plateNumber,
        type: result['type'] as String,
        description: result['description'] as String,
        status: MaintenanceStatus.pending,
        priority: result['priority'] as MaintenancePriority,
        preferredDate: result['preferredDate'] as DateTime?,
        createdAt: now,
      );
      _nextMntId++;

      setState(() => _maintenanceRecords.add(newRecord));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Maintenance request submitted'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(FleetSpacing.xl, FleetSpacing.xl, FleetSpacing.xl, 0),
              child: Row(
                children: [
                  Flexible(child: Text('Vehicle Maintenance', style: theme.textTheme.headlineLarge)),
                  const SizedBox(width: FleetSpacing.md),
                  FilledButton.icon(
                    onPressed: _showSubmitRequestDialog,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Request'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FleetSpacing.md),
            Expanded(
              child: _isLoading
                  ? Center(child: LoadingAnimationWidget.staggeredDotsWave(color: theme.colorScheme.primary, size: 50))
                  : _buildContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final pending = _maintenanceRecords.where((r) => r.status == MaintenanceStatus.pending).toList();
    final scheduled = _maintenanceRecords.where((r) => r.status == MaintenanceStatus.scheduled || r.status == MaintenanceStatus.inProgress).toList();
    final completed = _maintenanceRecords.where((r) => r.status == MaintenanceStatus.completed).toList();
    final rejected = _maintenanceRecords.where((r) => r.status == MaintenanceStatus.cancelled).toList();

    return ListView(
      padding: const EdgeInsets.all(FleetSpacing.lg),
      children: [
        _buildVehicleHeader(theme),
        const SizedBox(height: FleetSpacing.lg),
        if (pending.isNotEmpty) ...[
          _buildSectionTitle(theme, 'Pending Requests'),
          const SizedBox(height: FleetSpacing.sm),
          ...pending.map((r) => Card(
            margin: const EdgeInsets.only(bottom: FleetSpacing.sm),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.hourglass_empty_rounded, color: AppTheme.warningAmber, size: 22),
              ),
              title: Text(r.type, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(
                r.preferredDate != null
                    ? 'Preferred: ${r.preferredDate!.toString().split(' ')[0]}'
                    : r.description,
                style: theme.textTheme.bodySmall,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warningAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(FleetRadius.pill),
                    ),
                    child: Text('Pending', style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.warningAmber, fontWeight: FontWeight.w600,
                    )),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.edit_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      onPressed: () => _showSubmitRequestDialog(existingRecord: r),
                    ),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: FleetSpacing.lg),
        ],
        _buildSectionTitle(theme, 'Scheduled & In Progress'),
        const SizedBox(height: FleetSpacing.sm),
        if (scheduled.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No active maintenance', style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
          )
        else
          ...scheduled.map((r) => _buildMaintenanceTile(theme, r)),
        const SizedBox(height: FleetSpacing.lg),
        if (rejected.isNotEmpty) ...[
          _buildSectionTitle(theme, 'Rejected Requests'),
          const SizedBox(height: FleetSpacing.sm),
          ...rejected.map((r) => _buildRejectedTile(theme, r)),
          const SizedBox(height: FleetSpacing.lg),
        ],
        _buildSectionTitle(theme, 'Service History'),
        const SizedBox(height: FleetSpacing.sm),
        if (completed.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No service history', style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
          )
        else
          ...completed.map((r) => _buildHistoryTile(theme, r)),
      ],
    );
  }

  Widget _buildVehicleHeader(ThemeData theme) {
    final truck = _truck;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(FleetSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_shipping_rounded,
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: FleetSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    truck?.plateNumber ?? 'N/A',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    truck?.truckId ?? 'No truck assigned',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (truck != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: truck.status == 'En Route'
                      ? AppTheme.successGreen.withValues(alpha: 0.15)
                      : theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(FleetRadius.pill),
                ),
                child: Text(
                  truck.status,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: truck.status == 'En Route'
                        ? AppTheme.successGreen
                        : theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMaintenanceTile(ThemeData theme, MaintenanceRecord record) {
    final isUrgent = record.priority == MaintenancePriority.critical || record.priority == MaintenancePriority.high;
    return Card(
      margin: const EdgeInsets.only(bottom: FleetSpacing.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isUrgent
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isUrgent ? Icons.warning_rounded : Icons.build_rounded,
            color: isUrgent
                ? theme.colorScheme.error
                : theme.colorScheme.secondary,
            size: 22,
          ),
        ),
        title: Text(
          record.type,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          record.scheduledDate != null
              ? 'Due: ${record.scheduledDate!.toString().split(' ')[0]}'
              : record.description,
          style: theme.textTheme.bodySmall,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isUrgent
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(FleetRadius.pill),
          ),
          child: Text(
            record.status.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isUrgent
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRejectedTile(ThemeData theme, MaintenanceRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: FleetSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(FleetSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.dangerRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cancel_outlined, color: AppTheme.dangerRed, size: 22),
            ),
            const SizedBox(width: FleetSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.type, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  if (record.rejectionReason != null && record.rejectionReason!.isNotEmpty)
                    Text(record.rejectionReason!, style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.dangerRed,
                    )),
                ],
              ),
            ),
            const SizedBox(width: FleetSpacing.sm),
            FilledButton.tonal(
              onPressed: () => _showSubmitRequestDialog(existingRecord: record),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Resubmit', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(ThemeData theme, MaintenanceRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: FleetSpacing.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.check_circle_outline,
            color: theme.colorScheme.onSurfaceVariant,
            size: 22,
          ),
        ),
        title: Text(
          record.type,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          record.completedDate != null
              ? '${record.completedDate!.toString().split(' ')[0]} • ${record.cost.toStringAsFixed(0)} PHP'
              : record.description,
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}
