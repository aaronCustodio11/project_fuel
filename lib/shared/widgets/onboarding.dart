import 'package:flutter/material.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

enum OnboardingRole { supplier, manager, driver }

Future<void> showOnboardingOverlay(
  BuildContext context, {
  required OnboardingRole role,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => _OnboardingOverlay(role: role),
  );
}

class _OnboardingOverlay extends StatefulWidget {
  final OnboardingRole role;

  const _OnboardingOverlay({required this.role});

  @override
  State<_OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<_OnboardingOverlay> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    final pages = _pagesForRole(widget.role);
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  List<_OnboardingPageData> _pagesForRole(OnboardingRole role) {
    return switch (role) {
      OnboardingRole.supplier => _supplierPages,
      OnboardingRole.manager => _managerPages,
      OnboardingRole.driver => _driverPages,
    };
  }

  static const _supplierPages = [
    _OnboardingPageData(
      icon: Icons.local_gas_station_rounded,
      title: 'Welcome to FleetSense',
      description:
          'Manage your entire fuel supply operation from one central hub. '
          'Track fleets, monitor users, and keep your business running '
          'efficiently.',
    ),
    _OnboardingPageData(
      icon: Icons.dashboard_outlined,
      title: 'Dashboard',
      description:
          'Get a complete overview of your supply operations. View key '
          'metrics, active deliveries, and system alerts at a glance.',
      imagePath:
          'assets/images/Onboarding/supplier/IntroDashboardSupplier.jpg',
    ),
    _OnboardingPageData(
      icon: Icons.people_outline,
      title: 'User Dashboard',
      description:
          'Manage all users across your supply network. Assign roles, '
          'track activity, and control access permissions.',
      imagePath:
          'assets/images/Onboarding/supplier/IntroUserDashboardSupplier.jpg',
    ),
    _OnboardingPageData(
      icon: Icons.local_gas_station_outlined,
      title: 'Fuel Monitoring',
      description:
          'Monitor fuel tank levels across your network in real time. '
          'Track inventory, detect low-stock conditions, and manage '
          'fuel distribution efficiently.',
      imagePath:
          'assets/images/Onboarding/supplier/IntroFuelMonitoringSupplier.jpg',
    ),
    _OnboardingPageData(
      icon: Icons.build_outlined,
      title: 'Maintenance',
      description:
          'Schedule and track maintenance for your entire fleet. Get '
          'service reminders and maintain detailed repair histories.',
      imagePath:
          'assets/images/Onboarding/supplier/IntroMaintenanceSupplier.jpg',
    ),
    _OnboardingPageData(
      icon: Icons.map_outlined,
      title: 'Fleet Tracking',
      description:
          'Monitor your tanker trucks in real time with live GPS tracking. '
          'View routes, ETAs, and optimize delivery schedules.',
      imagePath:
          'assets/images/Onboarding/supplier/IntroFleetTrackingSupplier.jpg',
    ),
    _OnboardingPageData(
      icon: Icons.security_outlined,
      title: 'Theft Detection',
      description:
          'Protect your fuel assets with intelligent monitoring. Detect '
          'unauthorized access and unusual activity instantly.',
      imagePath:
          'assets/images/Onboarding/supplier/IntroTheftDetectionSupplier.jpg',
    ),
    _OnboardingPageData(
      icon: Icons.settings_outlined,
      title: 'Preferences',
      description: 'Customize your experience before you start.',
    ),
  ];

  static const _managerPages = [
    _OnboardingPageData(
      icon: Icons.local_gas_station_rounded,
      title: 'Welcome to FleetSense',
      description:
          'Oversee fuel station operations with real-time insights and '
          'control. Monitor fuel levels, detect issues, and manage your '
          'station efficiently.',
    ),
    _OnboardingPageData(
      icon: Icons.dashboard_outlined,
      title: 'Dashboard',
      description:
          'View key performance indicators for your station. Track fuel '
          'inventory, sales metrics, and operational status at a glance.',
      imagePath:
          'assets/images/Onboarding/manager/IntroDashboardManager.jpg',
    ),
    _OnboardingPageData(
      icon: Icons.local_gas_station_outlined,
      title: 'Fuel Monitoring',
      description:
          'Monitor fuel tank levels, dispensed volumes, and inventory in '
          'real time. Get low-stock alerts and track consumption patterns.',
      imagePath:
          'assets/images/Onboarding/manager/IntroFuelMonitoringManager.jpg',
    ),
    _OnboardingPageData(
      icon: Icons.map_outlined,
      title: 'Fleet Tracking',
      description:
          'Track your tanker trucks in real time with live GPS monitoring. '
          'View routes, ETAs, and optimize station deliveries.',
      imagePath:
          'assets/images/Onboarding/manager/IntroFleetTrackingManager.jpg',
    ),
    _OnboardingPageData(
      icon: Icons.security_outlined,
      title: 'Theft Detection',
      description:
          'Detect and prevent fuel theft with smart monitoring systems. '
          'Receive instant alerts on suspicious activity.',
      imagePath:
          'assets/images/Onboarding/manager/IntroTheftDetectionManager.jpg',
    ),
    _OnboardingPageData(
      icon: Icons.settings_outlined,
      title: 'Preferences',
      description: 'Customize your experience before you start.',
    ),
  ];

  static const _driverPages = [
    _OnboardingPageData(
      icon: Icons.local_gas_station_rounded,
      title: 'Welcome to FleetSense',
      description:
          'Your all-in-one tool for managing fuel deliveries on the road. '
          'Navigate routes, track deliveries, and keep your truck in top '
          'condition.',
    ),
    _OnboardingPageData(
      icon: Icons.map_outlined,
      title: 'Live Map',
      description:
          'View your assigned routes and navigate to delivery locations '
          'with real-time GPS tracking and turn-by-turn directions.',
      imagePath:
          'assets/images/Onboarding/driver/IntroMapDriver.jpg',
    ),
    _OnboardingPageData(
      icon: Icons.build_outlined,
      title: 'Maintenance',
      description:
          'Keep your truck in top condition. View maintenance schedules, '
          'report issues, and track service history.',
      imagePath:
          'assets/images/Onboarding/driver/IntroMaintenanceDriver.jpg',
    ),
    _OnboardingPageData(
      icon: Icons.route_outlined,
      title: 'Deliveries',
      description:
          'View your delivery schedule, check order details, and update '
          'delivery statuses in real time.',
      imagePath:
          'assets/images/Onboarding/driver/IntroDeliveriesDriver.jpg',
    ),
    _OnboardingPageData(
      icon: Icons.person_outline,
      title: 'Profile',
      description:
          'Manage your account settings, view your schedule, and update '
          'personal information from your profile.',
      imagePath:
          'assets/images/Onboarding/driver/IntroAccountDriver.jpg',
    ),
    _OnboardingPageData(
      icon: Icons.settings_outlined,
      title: 'Preferences',
      description: 'Customize your experience before you start.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = _pagesForRole(widget.role);
    final isLastPage = _currentPage == pages.length - 1;
    final isLandscapeRole = widget.role != OnboardingRole.driver;
    final screen = MediaQuery.of(context);
    final isMobile = screen.size.width < 600;
    final maxW = isMobile
        ? screen.size.width * 0.95
        : isLandscapeRole
            ? 680.0
            : 520.0;
    final maxH = isMobile ? screen.size.height * 0.85 : 640.0;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 12 : 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FleetRadius.lg),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
        child: Column(
          children: [
            _buildTimelineHeader(theme, pages.length),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: pages.length,
                itemBuilder: (_, i) => _buildPage(
                      theme, pages[i], isMobile, isLandscapeRole, i, pages.length,
                    ),
              ),
            ),
            _buildBottomBar(theme, isMobile, isLastPage),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineHeader(ThemeData theme, int pageCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(FleetRadius.lg),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Step ${_currentPage + 1} of $pageCount',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 32,
            child: Row(
              children: List.generate(pageCount * 2 - 1, (i) {
                if (i.isEven) {
                  final stepIndex = i ~/ 2;
                  return _TimelineDot(
                    index: stepIndex,
                    isActive: stepIndex == _currentPage,
                    isDone: stepIndex < _currentPage,
                  );
                }
                final leftIndex = i ~/ 2;
                final isDone = leftIndex < _currentPage;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                  color: isDone
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(
    ThemeData theme,
    _OnboardingPageData data,
    bool isMobile,
    bool isLandscapeRole,
    int pageIndex,
    int pageCount,
  ) {
    if (pageIndex == pageCount - 1) {
      return _buildThemeSetupPage(theme, isMobile);
    }
    if (data.imagePath == null) {
      return _buildPortraitPage(theme, data, isMobile);
    }
    if (isLandscapeRole) {
      return _buildLandscapePage(theme, data, isMobile, pageIndex);
    }
    return _buildDriverPage(theme, data, isMobile);
  }

  Widget _buildThemeSetupPage(ThemeData theme, bool isMobile) {
    return const _ThemeSetupPage();
  }

  Widget _buildPortraitPage(ThemeData theme, _OnboardingPageData data, bool isMobile) {
    final iconSize = isMobile ? 56.0 : 72.0;
    final boxSize = isMobile ? 120.0 : 160.0;
    final titleSize = isMobile ? 20.0 : 22.0;
    final paddingV = isMobile ? 32.0 : 48.0;
    final paddingH = isMobile ? 28.0 : 40.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(paddingH, paddingV, paddingH, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(FleetRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                data.icon,
                size: iconSize,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 28 : 36),
          Text(
            data.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 10 : 14),
          Text(
            data.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDriverPage(ThemeData theme, _OnboardingPageData data, bool isMobile) {
    final iconSize = isMobile ? 32.0 : 40.0;
    final titleSize = isMobile ? 20.0 : 22.0;
    final paddingH = isMobile ? 24.0 : 32.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(paddingH, 0, paddingH, 12),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(FleetRadius.md),
              child: Image.asset(
                data.imagePath!,
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Icon(
            data.icon,
            size: iconSize,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: isMobile ? 8 : 10),
          Text(
            data.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            data.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapePage(
    ThemeData theme,
    _OnboardingPageData data,
    bool isMobile,
    int pageIndex,
  ) {
    final isReversed = pageIndex.isEven;
    final padding = isMobile ? 16.0 : 24.0;

    final textSide = Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            data.icon,
            size: isMobile ? 32 : 40,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            data.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            data.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );

    final imageSide = ClipRRect(
      borderRadius: BorderRadius.circular(FleetRadius.md),
      child: Image.asset(
        data.imagePath!,
        fit: BoxFit.contain,
        alignment: Alignment.center,
      ),
    );

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Row(
        children: [
          Expanded(flex: 5, child: isReversed ? imageSide : textSide),
          SizedBox(width: isMobile ? 16 : 24),
          Expanded(flex: 5, child: isReversed ? textSide : imageSide),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, bool isMobile, bool isLastPage) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 20,
        12,
        isMobile ? 12 : 20,
        isMobile ? 16 : 20,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
            child: const Text('Skip'),
          ),
          const Spacer(),
          if (_currentPage > 0)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: OutlinedButton.icon(
                onPressed: _onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back'),
              ),
            ),
          FilledButton.icon(
            onPressed: _onNext,
            icon: Icon(
              isLastPage ? Icons.check_rounded : Icons.arrow_forward_rounded,
              size: 18,
            ),
            label: Text(isLastPage ? 'Get Started' : 'Next'),
          ),
        ],
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  final int index;
  final bool isActive;
  final bool isDone;

  const _TimelineDot({
    required this.index,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 28.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive || isDone
            ? theme.colorScheme.primary
            : Colors.transparent,
        border: Border.all(
          color: isActive || isDone
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          width: 2.5,
        ),
      ),
      child: Center(
        child: isDone
            ? Icon(Icons.check, size: 16, color: theme.colorScheme.onPrimary)
            : Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
      ),
    );
  }
}

class _ThemeSetupPage extends StatefulWidget {
  const _ThemeSetupPage();

  @override
  State<_ThemeSetupPage> createState() => _ThemeSetupPageState();
}

class _ThemeSetupPageState extends State<_ThemeSetupPage> {
  late ThemeMode _selectedTheme;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _selectedTheme = ThemeMode.system;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 400;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 20 : 32,
        isCompact ? 20 : 32,
        isCompact ? 20 : 32,
        12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tune_rounded,
            size: isCompact ? 44 : 52,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: isCompact ? 12 : 16),
          Text(
            'Preferences',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: isCompact ? 4 : 8),
          Text(
            'Customize your experience before you start.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isCompact ? 20 : 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(FleetSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, size: 20, color: scheme.primary),
                      const SizedBox(width: FleetSpacing.sm),
                      Text(
                        'Appearance',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FleetSpacing.md),
                  _ThemeOption(
                    value: ThemeMode.system,
                    groupValue: _selectedTheme,
                    icon: Icons.settings_brightness_outlined,
                    label: 'System',
                    subtitle: 'Match your device settings',
                    onChanged: (v) {
                      setState(() => _selectedTheme = v);
                      ThemeProvider.setThemeMode(context, v);
                    },
                  ),
                  const SizedBox(height: FleetSpacing.xs),
                  _ThemeOption(
                    value: ThemeMode.light,
                    groupValue: _selectedTheme,
                    icon: Icons.light_mode_outlined,
                    label: 'Light',
                    subtitle: 'Always light mode',
                    onChanged: (v) {
                      setState(() => _selectedTheme = v);
                      ThemeProvider.setThemeMode(context, v);
                    },
                  ),
                  const SizedBox(height: FleetSpacing.xs),
                  _ThemeOption(
                    value: ThemeMode.dark,
                    groupValue: _selectedTheme,
                    icon: Icons.dark_mode_outlined,
                    label: 'Dark',
                    subtitle: 'Always dark mode',
                    onChanged: (v) {
                      setState(() => _selectedTheme = v);
                      ThemeProvider.setThemeMode(context, v);
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isCompact ? 12 : 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(FleetSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.notifications_outlined, size: 20, color: scheme.primary),
                  const SizedBox(width: FleetSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Receive push notifications',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final ThemeMode value;
  final ThemeMode groupValue;
  final IconData icon;
  final String label;
  final String subtitle;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeOption({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(FleetRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FleetSpacing.sm,
          vertical: FleetSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: FleetSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Radio<ThemeMode>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final String? imagePath;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    this.imagePath,
  });
}
