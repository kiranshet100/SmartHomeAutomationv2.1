import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/auth_provider.dart' as custom_auth;
import 'providers/device_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/energy_monitoring_screen.dart';
import 'screens/automation_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/navigation_wrapper.dart';
import 'services/notification_service.dart';
import 'services/voice_service.dart';
import 'services/background_service.dart';
import 'services/sensor_monitor_service.dart';
import 'theme/app_theme.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      if (e.toString().contains('duplicate-app')) {
        // Ignore duplicate app error
        debugPrint('Firebase already initialized: $e');
      } else {
        rethrow;
      }
    }

    // Initialize voice service
    await VoiceService.initialize();

    // Initialize background service
    if (!kIsWeb) {
      await initializeService();
    }

    // Initialize shared preferences
    final prefs = await SharedPreferences.getInstance();

    runApp(MyApp(prefs: prefs));
  } catch (e, stackTrace) {
    print('Initialization Error: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Initialization Error:\n$e\n\n$stackTrace',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;

  const MyApp({Key? key, required this.prefs}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<custom_auth.AuthProvider>(
          create: (_) => custom_auth.AuthProvider(),
        ),
        ChangeNotifierProvider<DeviceProvider>(
          create: (_) {
            final provider = DeviceProvider();
            // Initialize notification service with device provider
            NotificationService().initialize(provider);
            // Initialize sensor monitor service
            SensorMonitorService().initialize(provider, NotificationService());
            return provider;
          },
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(widget.prefs),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Smart Home',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: const AuthWrapper(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/register': (context) => const RegisterScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/energy': (context) => const EnergyMonitoringScreen(),
              '/automation': (context) => const AutomationScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final authProvider =
        Provider.of<custom_auth.AuthProvider>(context, listen: false);

    // Check if user is already logged in
    final isLoggedIn = await authProvider.checkAuthState();

    if (mounted) {
      if (isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const NavigationWrapper()),
        );
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
