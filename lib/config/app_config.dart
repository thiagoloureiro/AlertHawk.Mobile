import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static late SharedPreferences _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String get monitoringApiUrl =>
      _prefs.getString('monitoring_api_url') ??
      dotenv.env['MONITORING_API_URL'] ??
      'https://monitoring.alerthawk.net';

  static String get authApiUrl =>
      _prefs.getString('auth_api_url') ??
      dotenv.env['AUTH_API_URL'] ??
      'https://auth.alerthawk.net/api';

  static String get notificationApiUrl =>
      _prefs.getString('notification_api_url') ??
      dotenv.env['NOTIFICATION_API_URL'] ??
      'https://notification.alerthawk.net/api';

  static String get azureAdTenant =>
      _prefs.getString('azure_ad_tenant') ??
      dotenv.env['AZURE_AD_TENANT'] ??
      'common';

  static String get azureAdClientId =>
      _prefs.getString('azure_ad_client_id') ??
      dotenv.env['AZURE_AD_CLIENT_ID'] ??
      'e6cc6189-3b58-4c15-a1c4-e24e9f5e4a97';

  static String get authApiKey =>
      _prefs.getString('auth_api_key') ??
      dotenv.env['AUTH_API_KEY'] ??
      'your_auth_api_key';
}
