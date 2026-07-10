import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project_fuel/core/routes/app_routes.dart';
import 'package:project_fuel/core/services/authentication.dart';
import 'package:project_fuel/core/theme/app_theme.dart';
import 'package:project_fuel/shared/widgets/logout_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _greetings = [
  'Good Morning',
  'Good Afternoon',
  'Good Evening',
  'Welcome Back',
  'Welcome',
  'Good to Have You',
  'Hello Again',
  'Great to See You',
  'Happy to Have You',
  'You\'re Signed In',
  'Back in Action',
  'Ready When You Are',
  'Let\'s Get Started',
  'Dashboard Ready',
  'System Online',
  'All Set',
  'Looking Good',
  'Everything Running Smoothly',
  'Glad You\'re Here',
  'Welcome to Your Dashboard',
];

String _dailyGreeting() {
  final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
  return _greetings[dayOfYear % _greetings.length];
}

const _avatarIcons = [
  Icons.person,
  Icons.person_outline,
  Icons.account_circle,
  Icons.face,
  Icons.emoji_people,
  Icons.tag_faces,
  Icons.sentiment_satisfied_alt,
  Icons.pets,
  Icons.android,
  Icons.rocket_launch,
  Icons.auto_awesome,
  Icons.palette,
  Icons.diamond,
  Icons.star,
  Icons.favorite,
  Icons.shield,
  Icons.psychology,
  Icons.explore,
  Icons.lightbulb,
  Icons.bolt,
];

class ProfileScreenPage extends StatelessWidget {
  const ProfileScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(FleetSpacing.xl, FleetSpacing.xl, FleetSpacing.xl, 0),
              child: Text('Profile', style: theme.textTheme.headlineLarge),
            ),
            const SizedBox(height: FleetSpacing.md),
            const Expanded(child: ProfileView()),
          ],
        ),
      ),
    );
  }
}

class ProfileView extends StatefulWidget {
  const ProfileView({super.key, this.isDesktop = false});

  final bool isDesktop;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AuthenticationService _authService = AuthenticationService();
  AuthUser? _user;
  bool _isLoading = true;
  int _avatarIndex = 0;

  IconData get _avatarIcon => _avatarIcons[_avatarIndex];

  @override
  void initState() {
    super.initState();
    _loadIconIndex();
    _loadUser();
  }

  Future<void> _loadIconIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('avatar_icon_index');
    if (index != null && index >= 0 && index < _avatarIcons.length && mounted) {
      setState(() => _avatarIndex = index);
    }
  }

  Future<void> _saveIconIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('avatar_icon_index', index);
  }

  Future<void> _loadUser() async {
    var user = await _authService.getSavedUser();
    if (user != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      final firstName = prefs.getString('profile_first_name');
      final surName = prefs.getString('profile_sur_name');
      final email = prefs.getString('profile_email');
      final company = prefs.getString('profile_company');
      if (firstName != null || surName != null || email != null || company != null) {
        user = AuthUser(
          userId: user.userId,
          firstName: firstName ?? user.firstName,
          surName: surName ?? user.surName,
          email: email ?? user.email,
          role: user.role,
          company: company ?? user.company,
          supplierId: user.supplierId,
          latitude: user.latitude,
          longitude: user.longitude,
        );
      }
    }
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

  Future<void> _showEditAvatarDialog() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Choose an avatar'),
          content: SizedBox(
            width: 400,
            child: Wrap(
              spacing: FleetSpacing.sm,
              runSpacing: FleetSpacing.sm,
              children: List.generate(_avatarIcons.length, (i) {
                final isSelected = i == _avatarIndex;
                return InkWell(
                  borderRadius: BorderRadius.circular(FleetRadius.sm),
                  onTap: () => Navigator.of(context).pop(i),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(FleetRadius.sm),
                      border: isSelected
                          ? Border.all(color: theme.colorScheme.primary, width: 2)
                          : null,
                    ),
                    child: Icon(_avatarIcons[i],
                        color: isSelected ? theme.colorScheme.primary : null),
                  ),
                );
              }),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _avatarIndex = result);
      _saveIconIndex(result);
    }
  }

  Future<void> _showEditDetailsDialog(AuthUser user) async {
    final firstNameCtrl = TextEditingController(text: user.firstName);
    final surNameCtrl = TextEditingController(text: user.surName);
    final emailCtrl = TextEditingController(text: user.email);
    final companyCtrl = TextEditingController(text: user.company);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile Details'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameCtrl,
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                const SizedBox(height: FleetSpacing.md),
                TextField(
                  controller: surNameCtrl,
                  decoration: const InputDecoration(labelText: 'Surname'),
                ),
                const SizedBox(height: FleetSpacing.md),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: FleetSpacing.md),
                TextField(
                  controller: companyCtrl,
                  decoration: const InputDecoration(labelText: 'Company'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved == true && mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Changes'),
          content: const Text('Are you sure you want to update your profile details?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_first_name', firstNameCtrl.text.trim());
        await prefs.setString('profile_sur_name', surNameCtrl.text.trim());
        await prefs.setString('profile_email', emailCtrl.text.trim());
        await prefs.setString('profile_company', companyCtrl.text.trim());

        setState(() {
          _user = AuthUser(
            userId: user.userId,
            firstName: firstNameCtrl.text.trim(),
            surName: surNameCtrl.text.trim(),
            email: emailCtrl.text.trim(),
            role: user.role,
            company: companyCtrl.text.trim(),
            supplierId: user.supplierId,
            latitude: user.latitude,
            longitude: user.longitude,
          );
        });
      }
    }

    firstNameCtrl.dispose();
    surNameCtrl.dispose();
    emailCtrl.dispose();
    companyCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: _isLoading
            ? Center(child: LoadingAnimationWidget.staggeredDotsWave(color: theme.colorScheme.primary, size: 50))
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  FleetSpacing.xl,
                  widget.isDesktop ? FleetSpacing.xxl * 2 : FleetSpacing.xl,
                  FleetSpacing.xl,
                  FleetSpacing.xl,
                ),
                child: _buildContent(theme, widget.isDesktop || isWide),
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

    if (widget.isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileSidebar(theme, user),
          const SizedBox(width: FleetSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGreetingCard(theme, user),
                const SizedBox(height: FleetSpacing.xl),
                Row(
                  children: [
                    Text('Account Details', style: theme.textTheme.headlineMedium),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () => _showEditDetailsDialog(user),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: FleetSpacing.md),
                _buildProfileCard(theme, user, showAvatar: false),
              ],
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(FleetSpacing.lg),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(_avatarIcon, size: 28, color: theme.colorScheme.primary),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Material(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _showEditAvatarDialog,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.edit_outlined, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: FleetSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dailyGreeting(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.fullName.isEmpty ? 'User Profile' : user.fullName,
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: FleetSpacing.lg),
          Row(
            children: [
              Text('Account Details', style: theme.textTheme.titleLarge),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _showEditDetailsDialog(user),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: FleetSpacing.md),
          _buildProfileCard(theme, user, showAvatar: false),
          const SizedBox(height: FleetSpacing.lg),
          _buildActionsCard(theme),
        ],
      ),
    );
  }

  Widget _buildGreetingCard(ThemeData theme, AuthUser user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(FleetSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dailyGreeting(),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: FleetSpacing.sm),
            Text(
              user.fullName.isEmpty ? 'User Profile' : user.fullName,
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: 28,
              ),
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
    );
  }

  Widget _buildProfileSidebar(ThemeData theme, AuthUser user) {
    return SizedBox(
      width: 360,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: FleetSpacing.xxl),
            CircleAvatar(
              radius: 150,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(_avatarIcon, size: 144, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: FleetSpacing.xl),
            OutlinedButton.icon(
              onPressed: _showEditAvatarDialog,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit profile picture'),
            ),
            const SizedBox(height: FleetSpacing.xl),
            _buildActionsCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme, AuthUser user, {bool showAvatar = true}) {
    final rowGap = widget.isDesktop ? FleetSpacing.lg : FleetSpacing.md;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(widget.isDesktop ? FleetSpacing.xxl : FleetSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAvatar)
              Padding(
                padding: const EdgeInsets.only(bottom: FleetSpacing.lg),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        _avatarIcon,
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
              ),
            _buildInfoRow(theme, Icons.person_outline, 'First Name', user.firstName),
            SizedBox(height: rowGap),
            _buildInfoRow(theme, Icons.person_outline, 'Surname', user.surName),
            SizedBox(height: rowGap),
            _buildInfoRow(theme, Icons.email_outlined, 'Email', user.email),
            SizedBox(height: rowGap),
            _buildInfoRow(
              theme,
              Icons.badge_outlined,
              'User ID',
              user.userId.toString(),
            ),
            SizedBox(height: rowGap),
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

  IconData _themeIcon(ThemeMode mode) => switch (mode) {
    ThemeMode.system => Icons.brightness_auto,
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
  };

  String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light mode',
    ThemeMode.dark => 'Dark mode',
  };

  Future<void> _showThemePickerDialog() async {
    final current = ThemeProvider.read(context);
    final result = await showDialog<ThemeMode>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: const Text('Choose theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _themeOption(ctx, theme, ThemeMode.system, current),
              const SizedBox(height: FleetSpacing.sm),
              _themeOption(ctx, theme, ThemeMode.light, current),
              const SizedBox(height: FleetSpacing.sm),
              _themeOption(ctx, theme, ThemeMode.dark, current),
            ],
          ),
        );
      },
    );
    if (result != null && mounted) {
      await _applyThemeWithLoading(context, result);
    }
  }

  Future<void> _applyThemeWithLoading(BuildContext ctx, ThemeMode mode) async {
    final navigator = Navigator.of(ctx);
    final theme = Theme.of(ctx);

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(FleetSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingAnimationWidget.staggeredDotsWave(color: theme.colorScheme.primary, size: 40),
                  const SizedBox(height: FleetSpacing.lg),
                  const Text('Hold on a second...'),
                  const SizedBox(height: FleetSpacing.xs),
                  Text(
                    'Changing appearance mode',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    ThemeProvider.setThemeMode(context, mode);
    navigator.pop();
  }

  Widget _themeOption(BuildContext ctx, ThemeData theme, ThemeMode mode, ThemeMode current) {
    final selected = mode == current;
    return Material(
      color: selected ? theme.colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(FleetRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(FleetRadius.sm),
        onTap: () => Navigator.of(ctx).pop(mode),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.lg, vertical: FleetSpacing.md),
          child: Row(
            children: [
              Icon(_themeIcon(mode), size: 20),
              const SizedBox(width: FleetSpacing.md),
              Text(_themeLabel(mode)),
              if (selected) ...[
                const Spacer(),
                Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsCard(ThemeData theme) {

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(FleetSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account', style: theme.textTheme.titleMedium),
            const SizedBox(height: FleetSpacing.md),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.lock_outline, size: 16),
              label: const Text('Change password'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.md, vertical: FleetSpacing.sm),
              ),
            ),
            const SizedBox(height: FleetSpacing.md),
            Text('Appearance', style: theme.textTheme.titleMedium),
            const SizedBox(height: FleetSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showThemePickerDialog,
                icon: Icon(_themeIcon(ThemeProvider.read(context)), size: 16),
                label: Text(_themeLabel(ThemeProvider.read(context))),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.md, vertical: FleetSpacing.sm),
                ),
              ),
            ),
            const SizedBox(height: FleetSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_outlined, size: 16),
                label: const Text('Logout'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.dangerRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: FleetSpacing.md, vertical: FleetSpacing.sm),
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
    final compact = !widget.isDesktop;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(compact ? FleetSpacing.sm : FleetSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(FleetRadius.sm),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: compact ? 20 : 24),
        ),
        SizedBox(width: compact ? FleetSpacing.md : FleetSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: compact ? theme.textTheme.labelMedium : theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(value, style: compact ? theme.textTheme.bodyLarge : theme.textTheme.titleLarge),
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
