import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_service.dart';
import 'providers/theme_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/app_config.dart';
import 'services/notification_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Global navigator key for MSAL authentication
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await AppConfig.initialize();
  final prefs = await SharedPreferences.getInstance();
  await NotificationService.init();

  await SentryFlutter.init((options) {
    options.dsn =
        'https://11cbdf51c6b3d17e1713aaeda8cfaae0@o418696.ingest.us.sentry.io/4508572122546176';
    // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
    // We recommend adjusting this value in production.
    options.tracesSampleRate = 1.0;
    // The sampling rate for profiling is relative to tracesSampleRate
    // Setting to 1.0 will profile 100% of sampled transactions:
    options.profilesSampleRate = 1.0;
  },
      appRunner: () => runApp(
            ChangeNotifierProvider(
              create: (_) => ThemeProvider(),
              child: MyApp(
                  isAuthenticated:
                      AuthService(prefs, navigatorKey).isAuthenticated()),
            ),
          ));
}

class MyApp extends StatelessWidget {
  final bool isAuthenticated;

  const MyApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          navigatorKey: navigatorKey, // Required for MSAL authentication
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
