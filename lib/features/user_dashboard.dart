import 'package:flutter/material.dart';
import 'package:project_fuel/core/services/json_reader.dart';
import 'package:project_fuel/core/theme/app_theme.dart';
import 'package:project_fuel/shared/widgets/sidebar.dart';

/// Dashboard-scoped user model.
/// NOTE: AuthUser (auth model) doesn't carry middleName, extensionName,
/// password, or plateNumber, so this dashboard uses its own model built
/// from the same mock JSON shape.
class ManagedUser {
  const ManagedUser({
    required this.userId,
    required this.firstName,
    this.middleName = '',
    required this.surName,
    this.extensionName = '',
    required this.company,
    required this.role,
    required this.email,
    required this.password,
    this.plateNumber,
    this.assignedSupplierId,
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
  final String password;
  final String? plateNumber;
  final String? assignedSupplierId; // Driver only — userId of the supplier
  final String? location; // Manager only

  String get fullName {
    final parts = [
      firstName,
      if (middleName.trim().isNotEmpty) middleName,
      surName,
      if (extensionName.trim().isNotEmpty) extensionName,
    ];
    return parts.join(' ');
  }

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    return ManagedUser(
      userId: json['userId'].toString(),
      firstName: json['firstName'] as String? ?? '',
      middleName: json['middleName'] as String? ?? '',
      surName: json['surName'] as String? ?? '',
      extensionName: json['extensionName'] as String? ?? '',
      company: json['company'] as String? ?? '',
      role: json['role'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      plateNumber: json['plateNumber'] as String?,
      assignedSupplierId: json['assignedSupplierId'] as String?,
      location: json['location'] as String?,
    );
  }

  ManagedUser copyWith({
    String? userId,
    String? firstName,
    String? middleName,
    String? surName,
    String? extensionName,
    String? company,
    String? role,
    String? email,
    String? password,
    String? plateNumber,
    String? assignedSupplierId,
    String? location,
  }) {
    return ManagedUser(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      surName: surName ?? this.surName,
      extensionName: extensionName ?? this.extensionName,
      company: company ?? this.company,
      role: role ?? this.role,
      email: email ?? this.email,
      password: password ?? this.password,
      plateNumber: plateNumber ?? this.plateNumber,
      assignedSupplierId: assignedSupplierId ?? this.assignedSupplierId,
      location: location ?? this.location,
    );
  }
}

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final JsonReaderService _jsonReader = JsonReaderService();
  static const String _dataPath = 'assets/mock_data/authentication.json';

  static const List<String> _roleFilters = [
    'All',
    'Manager',
    'Driver',
    'Supplier',
  ];

  List<ManagedUser> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String _roleFilter = 'All';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // TODO: replace with a real fetch (API / local DB) when ready.
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final raw = await _jsonReader.readList(_dataPath);
      final users = raw
          .whereType<Map<String, dynamic>>()
          .map(ManagedUser.fromJson)
          .toList();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  String _generateUserId() {
    final next = _users.length + 1;
    return 'USR-${next.toString().padLeft(4, '0')}';
  }

  // TODO: replace with a real create call. In-memory only for now —
  // bundled JSON assets can't be written back to at runtime.
  void _addUser(ManagedUser user) {
    setState(() {
      _users = [..._users, user.copyWith(userId: _generateUserId())];
    });
  }

  // TODO: replace with a real update call.
  void _updateUser(ManagedUser updated) {
    setState(() {
      _users = _users
          .map((u) => u.userId == updated.userId ? updated : u)
          .toList();
    });
  }

  // TODO: replace with a real delete call.
  void _deleteUser(String userId) {
    setState(() {
      _users = _users.where((u) => u.userId != userId).toList();
    });
  }

  List<ManagedUser> get _filteredUsers {
    final query = _searchQuery.trim().toLowerCase();
    return _users.where((u) {
      final matchesRole = _roleFilter == 'All' || u.role == _roleFilter;
      if (!matchesRole) return false;
      if (query.isEmpty) return true;
      return u.fullName.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query) ||
          u.userId.toLowerCase().contains(query) ||
          u.company.toLowerCase().contains(query);
    }).toList();
  }

  int _countByRole(String role) => _users.where((u) => u.role == role).length;

  void _openAddDialog() {
    final suppliers = _users.where((u) => u.role == 'Supplier').toList();
    showDialog(
      context: context,
      builder: (_) => _UserFormDialog(
        suppliers: suppliers,
        onSubmit: _addUser,
      ),
    );
  }

  void _openEditDialog(ManagedUser user) {
    final suppliers = _users
        .where((u) => u.role == 'Supplier' && u.userId != user.userId)
        .toList();
    showDialog(
      context: context,
      builder: (_) => _UserFormDialog(
        existingUser: user,
        suppliers: suppliers,
        onSubmit: _updateUser,
      ),
    );
  }

  void _confirmDelete(ManagedUser user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FleetRadius.md),
        ),
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.fullName}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _deleteUser(user.userId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // SidebarX is a nav rail only (unlike CollapsibleSidebar, it doesn't
    // own the page body), so it sits as a sibling in a Row alongside
    // the dashboard content.
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: SafeArea(
        child: Row(
          children: [
            const Sidebar(),
            Expanded(child: _buildDashboardContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(FleetSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User Management',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              FilledButton.icon(
                onPressed: _openAddDialog,
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Add User'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: FleetSpacing.xl),
          if (!_isLoading && _errorMessage == null) _buildAnalytics(context),
          if (!_isLoading && _errorMessage == null)
            const SizedBox(height: FleetSpacing.xl),
          if (!_isLoading && _errorMessage == null) _buildToolbar(context),
          if (!_isLoading && _errorMessage == null)
            const SizedBox(height: FleetSpacing.lg),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildAnalytics(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _AnalyticsCard(
            label: 'Total Users',
            value: _users.length.toString(),
            icon: Icons.groups_outlined,
            accentColor: scheme.primary,
          ),
        ),
        const SizedBox(width: FleetSpacing.md),
        Expanded(
          child: _AnalyticsCard(
            label: 'Managers',
            value: _countByRole('Manager').toString(),
            icon: Icons.badge_outlined,
            accentColor: AppTheme.accentBlue,
          ),
        ),
        const SizedBox(width: FleetSpacing.md),
        Expanded(
          child: _AnalyticsCard(
            label: 'Drivers',
            value: _countByRole('Driver').toString(),
            icon: Icons.local_shipping_outlined,
            accentColor: AppTheme.warningAmber,
          ),
        ),
        const SizedBox(width: FleetSpacing.md),
        Expanded(
          child: _AnalyticsCard(
            label: 'Suppliers',
            value: _countByRole('Supplier').toString(),
            icon: Icons.inventory_2_outlined,
            accentColor: AppTheme.brandGreenDark,
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search by name, email, company, or user ID',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(width: FleetSpacing.md),
        DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(FleetRadius.sm),
            ),
            child: DropdownButton<String>(
              value: _roleFilter,
              icon: const Icon(Icons.filter_list, size: 18),
              items: _roleFilters
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r == 'All' ? 'All Roles' : r),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _roleFilter = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, style: TextStyle(color: AppTheme.dangerRed)),
            const SizedBox(height: FleetSpacing.md),
            OutlinedButton(onPressed: _loadUsers, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_users.isEmpty) {
      return const Center(child: Text('No users yet.'));
    }
    final filtered = _filteredUsers;
    if (filtered.isEmpty) {
      return const Center(child: Text('No users match your search/filter.'));
    }
    return _buildUserTable(context, filtered);
  }

  Widget _buildUserTable(BuildContext context, List<ManagedUser> users) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(scheme.surfaceContainerLow),
            columns: const [
              DataColumn(label: Text('User ID')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Company')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Plate Number')),
              DataColumn(label: Text('Actions')),
            ],
            rows: users.map((user) {
              return DataRow(
                cells: [
                  DataCell(Text(user.userId)),
                  DataCell(Text(user.fullName)),
                  DataCell(Text(user.company)),
                  DataCell(_buildRoleChip(context, user.role)),
                  DataCell(Text(user.email)),
                  DataCell(Text(user.plateNumber ?? '—')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit',
                          onPressed: () => _openEditDialog(user),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppTheme.dangerRed,
                          ),
                          tooltip: 'Delete',
                          onPressed: () => _confirmDelete(user),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(BuildContext context, String role) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(FleetRadius.pill),
      ),
      child: Text(
        role,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSecondaryContainer,
            ),
      ),
    );
  }
}

/// Small stat card used in the analytics row, with a colored left accent
/// bar matching the category it represents.
class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

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
                    Column(
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
                      ],
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

/// Modal form used for both Add and Edit.
class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({
    this.existingUser,
    required this.suppliers,
    required this.onSubmit,
  });

  final ManagedUser? existingUser;
  final List<ManagedUser> suppliers;
  final void Function(ManagedUser user) onSubmit;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _middleNameCtrl;
  late final TextEditingController _surNameCtrl;
  late final TextEditingController _extensionNameCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _plateNumberCtrl;
  late final TextEditingController _locationCtrl;

  static const _roles = ['Manager', 'Driver', 'Supplier'];
  late String _selectedRole;
  String? _selectedSupplierId;
  bool _obscurePassword = true;

  bool get _isEditing => widget.existingUser != null;

  @override
  void initState() {
    super.initState();
    final u = widget.existingUser;
    _firstNameCtrl = TextEditingController(text: u?.firstName ?? '');
    _middleNameCtrl = TextEditingController(text: u?.middleName ?? '');
    _surNameCtrl = TextEditingController(text: u?.surName ?? '');
    _extensionNameCtrl = TextEditingController(text: u?.extensionName ?? '');
    _companyCtrl = TextEditingController(text: u?.company ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _passwordCtrl = TextEditingController();
    _plateNumberCtrl = TextEditingController(text: u?.plateNumber ?? '');
    _locationCtrl = TextEditingController(text: u?.location ?? '');
    // Fall back to the first available role if the existing user's role
    // is no longer selectable (e.g. an old "Admin" record).
    _selectedRole = _roles.contains(u?.role) ? u!.role : _roles.first;
    _selectedSupplierId = u?.assignedSupplierId;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _surNameCtrl.dispose();
    _extensionNameCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _plateNumberCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final user = ManagedUser(
      userId: widget.existingUser?.userId ?? '',
      firstName: _firstNameCtrl.text.trim(),
      middleName: _middleNameCtrl.text.trim(),
      surName: _surNameCtrl.text.trim(),
      extensionName: _extensionNameCtrl.text.trim(),
      company: _companyCtrl.text.trim(),
      role: _selectedRole,
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.isNotEmpty
          ? _passwordCtrl.text
          : (widget.existingUser?.password ?? ''),
      plateNumber:
          _selectedRole == 'Driver' ? _plateNumberCtrl.text.trim() : null,
      assignedSupplierId:
          _selectedRole == 'Driver' ? _selectedSupplierId : null,
      location: _selectedRole == 'Manager' ? _locationCtrl.text.trim() : null,
    );

    widget.onSubmit(user);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FleetRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(FleetSpacing.xl),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing ? 'Edit User' : 'Add User',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: FleetSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _firstNameCtrl,
                          label: 'First Name',
                          required: true,
                        ),
                      ),
                      const SizedBox(width: FleetSpacing.md),
                      Expanded(
                        child: _buildTextField(
                          controller: _middleNameCtrl,
                          label: 'Middle Name',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FleetSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _surNameCtrl,
                          label: 'Surname',
                          required: true,
                        ),
                      ),
                      const SizedBox(width: FleetSpacing.md),
                      Expanded(
                        child: _buildTextField(
                          controller: _extensionNameCtrl,
                          label: 'Extension (Jr., III...)',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FleetSpacing.md),
                  _buildTextField(
                    controller: _companyCtrl,
                    label: 'Company',
                    required: true,
                  ),
                  const SizedBox(height: FleetSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: _roles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                          // Clear role-specific fields when switching away
                          if (value != 'Driver') _selectedSupplierId = null;
                          if (value != 'Manager') _locationCtrl.clear();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: FleetSpacing.md),
                  _buildTextField(
                    controller: _emailCtrl,
                    label: 'Email',
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: FleetSpacing.md),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: _isEditing
                          ? 'Password (leave blank to keep current)'
                          : 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (!_isEditing && (value == null || value.isEmpty)) {
                        return 'Password is required';
                      }
                      if (value != null &&
                          value.isNotEmpty &&
                          value.length < 6) {
                        return 'Minimum 6 characters';
                      }
                      return null;
                    },
                  ),
                  if (_selectedRole == 'Driver') ...[
                    const SizedBox(height: FleetSpacing.md),
                    _buildTextField(
                      controller: _plateNumberCtrl,
                      label: 'Plate Number',
                      required: true,
                    ),
                    const SizedBox(height: FleetSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSupplierId,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Supplier',
                      ),
                      items: widget.suppliers
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.userId,
                              child: Text(s.fullName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedSupplierId = value),
                      validator: (value) {
                        if (widget.suppliers.isEmpty) return null;
                        return value == null
                            ? 'Please select a supplier'
                            : null;
                      },
                      hint: widget.suppliers.isEmpty
                          ? const Text('No suppliers available yet')
                          : const Text('Select a supplier'),
                    ),
                  ],
                  if (_selectedRole == 'Manager') ...[
                    const SizedBox(height: FleetSpacing.md),
                    _buildTextField(
                      controller: _locationCtrl,
                      label: 'Location',
                      required: true,
                    ),
                  ],
                  const SizedBox(height: FleetSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: FleetSpacing.sm),
                      FilledButton(
                        onPressed: _handleSubmit,
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.primary,
                        ),
                        child: Text(_isEditing ? 'Save Changes' : 'Add User'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(label: Text(label)),
      validator: validator ??
          (required
              ? (value) => (value == null || value.trim().isEmpty)
                  ? '$label is required'
                  : null
              : null),
    );
  }
}