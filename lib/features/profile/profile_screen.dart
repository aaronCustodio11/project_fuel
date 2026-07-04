import 'package:flutter/material.dart';
import 'package:project_fuel/core/routes/app_routes.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

class ProfileScreenPage extends StatefulWidget {
  const ProfileScreenPage({super.key});

  @override
  State<ProfileScreenPage> createState() => _ProfileScreenPageState();
}

class _ProfileScreenPageState extends State<ProfileScreenPage> {
  final AuthenticationService _authService = AuthenticationService();
  AuthUser? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getSavedUser();
    if (!mounted) return;

    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(FleetSpacing.xl),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(theme, isWide),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isWide) {
    final user = _user;

    if (user == null) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(FleetSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_off_outlined, size: 40),
                const SizedBox(height: FleetSpacing.md),
                Text(
                  'No active profile found.',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: FleetSpacing.sm),
                Text(
                  'Please sign in again to view your profile.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profileCard = _buildProfileCard(theme, user);
    final actionCard = _buildActionsCard(theme);

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: profileCard),
          const SizedBox(width: FleetSpacing.lg),
          Expanded(flex: 1, child: actionCard),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          profileCard,
          const SizedBox(height: FleetSpacing.lg),
          actionCard,
        ],
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme, AuthUser user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(FleetSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: FleetSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName.isEmpty ? 'User Profile' : user.fullName,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: FleetSpacing.xs),
                      Wrap(
                        spacing: FleetSpacing.sm,
                        runSpacing: FleetSpacing.sm,
                        children: [
                          _buildChip(
                            theme,
                            user.role,
                            theme.colorScheme.primaryContainer,
                            theme.colorScheme.onPrimaryContainer,
                          ),
                          _buildChip(
                            theme,
                            user.company,
                            theme.colorScheme.secondaryContainer,
                            theme.colorScheme.onSecondaryContainer,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: FleetSpacing.xl),
            _buildInfoRow(theme, Icons.email_outlined, 'Email', user.email),
            const SizedBox(height: FleetSpacing.lg),
            _buildInfoRow(
              theme,
              Icons.badge_outlined,
              'User ID',
              user.userId.toString(),
            ),
            const SizedBox(height: FleetSpacing.lg),
            _buildInfoRow(
              theme,
              Icons.business_outlined,
              'Company',
              user.company.isEmpty ? 'Not available' : user.company,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(FleetSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account actions', style: theme.textTheme.headlineSmall),
            const SizedBox(height: FleetSpacing.sm),
            Text(
              'Use these controls to manage your account details.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: FleetSpacing.lg),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit user details'),
            ),
            const SizedBox(height: FleetSpacing.md),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Change password'),
            ),
            const SizedBox(height: FleetSpacing.md),
            FilledButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout_outlined),
              label: const Text('Logout'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.dangerRed,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: FleetSpacing.md),
            Text(
              'Only the logout action is currently enabled.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(FleetSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(FleetRadius.sm),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: FleetSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(
    ThemeData theme,
    String label,
    Color backgroundColor,
    Color foregroundColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(FleetRadius.pill),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: foregroundColor),
      ),
    );
  }
}
