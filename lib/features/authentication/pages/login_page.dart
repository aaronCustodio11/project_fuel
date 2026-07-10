import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project_fuel/core/services/authentication.dart';

class LoginScreenPage extends StatefulWidget {
  const LoginScreenPage({super.key});

  @override
  State<LoginScreenPage> createState() => _LoginScreenPageState();
}

class _LoginScreenPageState extends State<LoginScreenPage>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthenticationService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _gradientController;
  late final Animation<double> _gradientAnim;
  late final AnimationController _listController;
  final _featureItems = const [
    'Get a complete overview of your operations',
    'Monitor fuel levels and consumption in real time',
    'Track your fleet with live GPS updates',
    'Manage vehicle maintenance schedules',
    'Detect and prevent fuel theft',
  ];

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _gradientAnim = CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    );
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _listController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _listController.reset();
            _listController.forward();
          }
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _listController.forward();
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _listController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = await _authService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid email or password.';
      });
      return;
    }

    setState(() {
      _isLoading = false;
    });

    final route = _authService.getRouteForRole(user.role);
    if (!mounted) return;

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 900;

            if (isWideScreen) {
              return Center(
                child: SizedBox(
                  width: 960,
                  height: 600,
                  child: Card(
                    elevation: 16,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: AnimatedBuilder(
                            animation: _gradientAnim,
                            builder: (context, child) => _buildLeftPanel(
                              theme,
                              _gradientAnim.value,
                            ),
                          ),
                        ),
                        Expanded(flex: 4, child: _buildRightPanel(theme)),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMobileLogo(),
                    const SizedBox(height: 24),
                    _buildFormCard(theme),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeftPanel(ThemeData theme, double animValue) {
    final isDark = theme.brightness == Brightness.dark;
    final gradientColors = isDark
        ? const [
            Color(0xFF1B4DB5),
            Color(0xFF153B6E),
            Color(0xFF0F2942),
            Color(0xFF0A1E30),
          ]
        : const [
            Color(0xFFA8F0FF),
            Color(0xFF7DD0F5),
            Color(0xFF5A8FF0),
            Color(0xFF4A7AE0),
          ];
    final titleColor = isDark ? Colors.white : const Color(0xFF001B5E);
    final bodyColor = isDark ? Colors.white70 : const Color(0xFF163B82);
    final mutedColor = isDark ? Colors.white38 : const Color(0xFF0F2942);

    final begin = Alignment.lerp(
      const Alignment(-0.8, -1.0),
      const Alignment(-0.4, -0.6),
      animValue,
    )!;
    final end = Alignment.lerp(
      const Alignment(1.2, 1.0),
      const Alignment(0.8, 0.6),
      animValue,
    )!;

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          stops: const [0.0, 0.35, 0.7, 1.0],
          colors: gradientColors,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/logo/logoTransparent.svg',
            width: 110,
            height: 110,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            'FLEET SENSE',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Every Drip Accounted For',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: bodyColor,
            ),
          ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _listController,
            builder: (context, _) => Column(
              children: [
                for (int i = 0; i < _featureItems.length; i++)
                  _buildFeatureItem(
                    _featureItems[i],
                    isDark,
                    progress: _itemProgress(i),
                  ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '© 2026 FleetSense',
            style: theme.textTheme.bodySmall?.copyWith(
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome Aboard',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to manage your fuel operations.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 36),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: LoadingAnimationWidget.waveDots(
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                    )
                  : const Text('Login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLogo() {
    final theme = Theme.of(context);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SvgPicture.asset(
            'assets/images/logo/logoTransparent.svg',
            width: 72,
            height: 72,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'FLEET SENSE',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Every Drip Accounted For',
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(ThemeData theme) {
    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Welcome Aboard', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Sign in to view your routes and deliveries.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _login(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Forgot Password?'),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: LoadingAnimationWidget.waveDots(
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                      )
                    : const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _itemProgress(int index) {
    final start = index * 0.15;
    final window = 0.3;
    final raw = (_listController.value - start) / window;
    return Curves.easeOut.transform(raw.clamp(0.0, 1.0));
  }

  Widget _buildFeatureItem(String text, bool isDark, {double progress = 1.0}) {
    final color = isDark ? Colors.white70 : const Color(0xFF163B82);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Opacity(
            opacity: progress,
            child: Transform.scale(
              scale: 0.5 + 0.5 * progress,
              child: Icon(
                Icons.check_circle_outline,
                size: 18,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
