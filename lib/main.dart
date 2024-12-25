import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_service.dart';
import 'providers/theme_provider.dart';

// Global navigator key for MSAL authentication
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(isAuthenticated: AuthService(prefs, navigatorKey).isAuthenticated()),
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
          navigatorKey: navigatorKey,  // Required for MSAL authentication
          title: 'AlertHawk',
          theme: themeProvider.theme,
          home: isAuthenticated ? const WelcomeScreen() : const LoginScreen(),
        );
      },
    );
  }
}
