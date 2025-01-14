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
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Global navigator key for MSAL authentication
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<bool> isEmulator() async {
  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    // Android
    final androidInfo = await deviceInfo.androidInfo;
    print(androidInfo.isPhysicalDevice);
    return androidInfo.isPhysicalDevice == false;
  } else if (Platform.isIOS) {
    // iOS
    final iosInfo = await deviceInfo.iosInfo;
    print(iosInfo.isPhysicalDevice);
    return iosInfo.isPhysicalDevice == false;
  }
  return true; // Default fallback for unsupported platforms
}

Future<void> _updateDeviceToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final deviceToken = prefs.getString('deviceToken');
    final token = prefs.getString('auth_token');

    if (deviceToken == null || token == null) {
      return;
    }
    await http.post(
      Uri.parse('${AppConfig.authApiUrl}/api/User/UpdateUserDeviceToken'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'deviceToken': deviceToken,
      }),
    );
  } catch (e) {
    print('Failed to update device token: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await AppConfig.initialize();
  final prefs = await SharedPreferences.getInstance();

  if (!await isEmulator()) {
    // Initialize Pushy
    try {
      // Register the device for push notifications
      String deviceToken = await Pushy.register();
      await prefs.setString('deviceToken', deviceToken);

      // Start the Pushy service
      Pushy.listen();

      // Clear iOS app badge number when app is launched
      Pushy.clearBadge();

      // Optional: Handle background notifications
      Pushy.setNotificationListener((Map<String, dynamic> data) async {
        // Store notification count
        final prefs = await SharedPreferences.getInstance();
        int currentCount = prefs.getInt('badge_count') ?? 0;
        await prefs.setInt('badge_count', currentCount + 1);

        // Display notification as alert
        String message = data['message'] ?? 'No message';
        Pushy.notify("AlertHawk", message, data);

        prefs.setString('notification', message);

        // Clear iOS app badge number
        Pushy.clearBadge();
      });

      Pushy.toggleInAppBanner(true);

      // Optional: Handle notification clicks
      Pushy.setNotificationClickListener((Map<String, dynamic> data) {
        print("listener");
        // Your custom notification click handling here
        // Clear iOS app badge number
        Pushy.clearBadge();
      });
      await _updateDeviceToken();
    } on PlatformException catch (error) {
      print('Failed to register for push notifications: $error');
    }
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
          debugShowCheckedModeBanner: false,
          home: isAuthenticated ? const WelcomeScreen() : const LoginScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
          },
        );
      },
    );
  }
}
