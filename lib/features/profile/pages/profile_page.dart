import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project_fuel/core/routes/app_routes.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/theme/app_theme.dart';
import 'package:project_fuel/shared/widgets/logout_dialog.dart';

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
    final confirmed = await showLogoutConfirmationDialog(context);
    if (!confirmed) return;
    if (!mounted) return;

    await _authService.logout();
    if (!mounted) return;

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(FleetSpacing.xl, FleetSpacing.xl, FleetSpacing.xl, 0),
              child: Text('Profile', style: theme.textTheme.headlineLarge),
            ),
            const SizedBox(height: FleetSpacing.md),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: _isLoading
                      ? Center(child: LoadingAnimationWidget.staggeredDotsWave(color: theme.colorScheme.primary, size: 50))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(FleetSpacing.xl),
                          child: _buildContent(theme, isWide),
                        ),
                ),
              ),
            ),
          ],
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
    final scheme = theme.colorScheme;
    final themeMode = ThemeProvider.read(context);
    final isLight = themeMode == ThemeMode.light ||
        (themeMode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.light);
    final themeIcon = isLight ? Icons.dark_mode_outlined : Icons.light_mode_outlined;
    final themeLabel = isLight ? 'Dark mode' : 'Light mode';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(FleetSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account', style: theme.textTheme.headlineSmall),
            const SizedBox(height: FleetSpacing.sm),
            Text(
              'Manage your account settings.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: FleetSpacing.lg),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Change password'),
            ),
            const SizedBox(height: FleetSpacing.xl),
            Text('Appearance', style: theme.textTheme.headlineSmall),
            const SizedBox(height: FleetSpacing.sm),
            Text(
              'Customise your display preferences.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: FleetSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => ThemeProvider.toggle(context),
              icon: Icon(themeIcon),
              label: Text(themeLabel),
            ),
            const SizedBox(height: FleetSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_outlined),
                label: const Text('Logout'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.dangerRed,
                  foregroundColor: Colors.white,
                ),
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
