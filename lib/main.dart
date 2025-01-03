import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_service.dart';
import 'providers/theme_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/app_config.dart';
import 'package:flutter/services.dart';
import 'package:pushy_flutter/pushy_flutter.dart';

// Global navigator key for MSAL authentication
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await AppConfig.initialize();
  final prefs = await SharedPreferences.getInstance();

  // Initialize Pushy
  try {
    // Register the device for push notifications
    String deviceToken = await Pushy.register();
    await prefs.setString('deviceToken', deviceToken);
    // Print token to console/logcat
    print('Device token: $deviceToken');

    // Start the Pushy service
    Pushy.listen();

    // Optional: Handle background notifications
    Pushy.setNotificationListener((Map<String, dynamic> data) {
      // Print notification payload data
      print('Received notification: $data');

      // Display notification as alert
      String message = data['message'] ?? 'No message';
      Pushy.notify("AlertHawk", message, data);
    });

    // Optional: Handle notification clicks
    Pushy.setNotificationClickListener((Map<String, dynamic> data) {
      // Print notification payload data
      print('Notification clicked: $data');

      // Your custom notification click handling here
    });
  } on PlatformException catch (error) {
    print('Failed to register for push notifications: $error');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(
          isAuthenticated: AuthService(prefs, navigatorKey).isAuthenticated()),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isAuthenticated;

  const MyApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'AlertHawk',
          theme: themeProvider.theme,
          home: isAuthenticated ? const WelcomeScreen() : const LoginScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
          },
        );
      },
    );
  }
}
