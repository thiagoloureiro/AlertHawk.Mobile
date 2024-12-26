import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get monitoringApiUrl =>
      dotenv.env['MONITORING_API_URL'] ?? 'https://monitoring.alerthawk.net';

  static String get authApiUrl =>
      dotenv.env['AUTH_API_URL'] ?? 'https://auth.alerthawk.net/api';

  static String get notificationApiUrl =>
      dotenv.env['NOTIFICATION_API_URL'] ??
      'https://notification.alerthawk.net/api';

  static String get azureAdTenant =>
      dotenv.env['AZURE_AD_TENANT'] ?? '326ac626-dcd5-4409-be50-481d4c0316e4';

  static String get azureAdClientId =>
      dotenv.env['AZURE_AD_CLIENT_ID'] ??
      'e6cc6189-3b58-4c15-a1c4-e24e9f5e4a97';

  static String get authApiKey =>
      dotenv.env['AUTH_API_KEY'] ?? 'your_auth_api_key';
}
