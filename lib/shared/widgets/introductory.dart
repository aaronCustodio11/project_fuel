import 'package:flutter/material.dart';
import 'package:project_fuel/core/theme/app_theme.dart';

enum IntroductoryRole { supplier, manager, driver }

Future<void> showIntroductoryOverlay(
  BuildContext context, {
  required IntroductoryRole role,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => _IntroductoryOverlay(role: role),
  );
}

class _IntroductoryOverlay extends StatefulWidget {
  final IntroductoryRole role;

  const _IntroductoryOverlay({required this.role});

  @override
  State<_IntroductoryOverlay> createState() => _IntroductoryOverlayState();
}

class _IntroductoryOverlayState extends State<_IntroductoryOverlay> {
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

  List<_IntroPageData> _pagesForRole(IntroductoryRole role) {
    return switch (role) {
      IntroductoryRole.supplier => _supplierPages,
      IntroductoryRole.manager => _managerPages,
      IntroductoryRole.driver => _driverPages,
    };
  }

  static const _supplierPages = [
    _IntroPageData(
      icon: Icons.local_gas_station_rounded,
      title: 'Welcome to FleetSense',
      description:
          'Manage your entire fuel supply operation from one central hub. '
          'Track fleets, monitor users, and keep your business running '
          'efficiently.',
    ),
    _IntroPageData(
      icon: Icons.dashboard_outlined,
      title: 'Dashboard',
      description:
          'Get a complete overview of your supply operations. View key '
          'metrics, active deliveries, and system alerts at a glance.',
    ),
    _IntroPageData(
      icon: Icons.people_outline,
      title: 'User Dashboard',
      description:
          'Manage all users across your supply network. Assign roles, '
          'track activity, and control access permissions.',
    ),
    _IntroPageData(
      icon: Icons.build_outlined,
      title: 'Maintenance',
      description:
          'Schedule and track maintenance for your entire fleet. Get '
          'service reminders and maintain detailed repair histories.',
    ),
    _IntroPageData(
      icon: Icons.map_outlined,
      title: 'Fleet Tracking',
      description:
          'Monitor your tanker trucks in real time with live GPS tracking. '
          'View routes, ETAs, and optimize delivery schedules.',
    ),
    _IntroPageData(
      icon: Icons.security_outlined,
      title: 'Theft Detection',
      description:
          'Protect your fuel assets with intelligent monitoring. Detect '
          'unauthorized access and unusual activity instantly.',
    ),
  ];

  static const _managerPages = [
    _IntroPageData(
      icon: Icons.local_gas_station_rounded,
      title: 'Welcome to FleetSense',
      description:
          'Oversee fuel station operations with real-time insights and '
          'control. Monitor fuel levels, detect issues, and manage your '
          'station efficiently.',
    ),
    _IntroPageData(
      icon: Icons.dashboard_outlined,
      title: 'Dashboard',
      description:
          'View key performance indicators for your station. Track fuel '
          'inventory, sales metrics, and operational status at a glance.',
    ),
    _IntroPageData(
      icon: Icons.local_gas_station_outlined,
      title: 'Fuel Monitoring',
      description:
          'Monitor fuel tank levels, dispensed volumes, and inventory in '
          'real time. Get low-stock alerts and track consumption patterns.',
    ),
    _IntroPageData(
      icon: Icons.security_outlined,
      title: 'Theft Detection',
      description:
          'Detect and prevent fuel theft with smart monitoring systems. '
          'Receive instant alerts on suspicious activity.',
    ),
  ];

  static const _driverPages = [
    _IntroPageData(
      icon: Icons.local_gas_station_rounded,
      title: 'Welcome to FleetSense',
      description:
          'Your all-in-one tool for managing fuel deliveries on the road. '
          'Navigate routes, track deliveries, and keep your truck in top '
          'condition.',
    ),
    _IntroPageData(
      icon: Icons.map_outlined,
      title: 'Live Map',
      description:
          'View your assigned routes and navigate to delivery locations '
          'with real-time GPS tracking and turn-by-turn directions.',
    ),
    _IntroPageData(
      icon: Icons.build_outlined,
      title: 'Maintenance',
      description:
          'Keep your truck in top condition. View maintenance schedules, '
          'report issues, and track service history.',
    ),
    _IntroPageData(
      icon: Icons.route_outlined,
      title: 'Deliveries',
      description:
          'View your delivery schedule, check order details, and update '
          'delivery statuses in real time.',
    ),
    _IntroPageData(
      icon: Icons.person_outline,
      title: 'Profile',
      description:
          'Manage your account settings, view your schedule, and update '
          'personal information from your profile.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = _pagesForRole(widget.role);
    final isLastPage = _currentPage == pages.length - 1;
    final screen = MediaQuery.of(context);
    final isMobile = screen.size.width < 600;
    final maxW = isMobile ? screen.size.width * 0.95 : 520.0;
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
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: pages.length,
                itemBuilder: (_, i) => _buildPage(theme, pages[i], isMobile),
              ),
            ),
            _buildBottomBar(theme, isMobile, isLastPage),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(ThemeData theme, _IntroPageData data, bool isMobile) {
    final iconSize = isMobile ? 56.0 : 72.0;
    final boxSize = isMobile ? 120.0 : 160.0;
    final paddingV = isMobile ? 24.0 : 40.0;
    final paddingH = isMobile ? 24.0 : 32.0;

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
            ),
            child: Center(
              child: Icon(
                data.icon,
                size: iconSize,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 24 : 32),
          Text(
            data.title,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            data.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, bool isMobile, bool isLastPage) {
    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 12 : 20, 12, isMobile ? 12 : 20, isMobile ? 12 : 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Skip'),
          ),
          const Spacer(),
          if (_currentPage > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: OutlinedButton(
                onPressed: _onBack,
                child: const Text('Back'),
              ),
            ),
          FilledButton(
            onPressed: _onNext,
            child: Text(isLastPage ? 'Get Started' : 'Next'),
          ),
        ],
      ),
    );
  }
}

class _IntroPageData {
  final IconData icon;
  final String title;
  final String description;

  const _IntroPageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
