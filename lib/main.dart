import 'package:flutter/material.dart';
import 'package:project_fuel/core/routes/app_routes.dart';
import 'package:project_fuel/core/routes/route_generator.dart';
import 'package:project_fuel/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('themeMode');
  final initialMode = switch (saved) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  runApp(ProjectFuelApp(initialThemeMode: initialMode));
}

class ProjectFuelApp extends StatefulWidget {
  const ProjectFuelApp({super.key, required this.initialThemeMode});

  final ThemeMode initialThemeMode;

  @override
  State<ProjectFuelApp> createState() => _ProjectFuelAppState();
}

class _ProjectFuelAppState extends State<ProjectFuelApp> {
  late final ValueNotifier<ThemeMode> _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = ValueNotifier(widget.initialThemeMode);
    _themeMode.addListener(_persistThemeMode);
  }

  Future<void> _persistThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final key = switch (_themeMode.value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefs.setString('themeMode', key);
  }

  @override
  void dispose() {
    _themeMode.removeListener(_persistThemeMode);
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      notifier: _themeMode,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeMode,
        builder: (context, themeMode, child) {
          return MaterialApp(
            title: 'FleetSense',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: RouteGenerator.generateRoute,
          );
        },
      ),
    );
  }
}
