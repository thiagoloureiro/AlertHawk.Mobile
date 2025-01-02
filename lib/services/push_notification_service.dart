import 'package:pushy_flutter/pushy_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;
import '../config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class PushNotificationService {
  final SharedPreferences _prefs;
  static const String _pushyTokenKey = 'pushy_token';

  PushNotificationService(this._prefs);

  Future<void> registerDevice(String userId) async {
    try {
      // Get the device token
      String deviceToken = await Pushy.register();

      // Save token locally
      await _prefs.setString(_pushyTokenKey, deviceToken);

      // Register token with your backend
      await http.post(
        Uri.parse('${AppConfig.notificationApiUrl}/api/notifications/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'deviceToken': deviceToken,
          'platform': Platform.isAndroid ? 'Android' : 'iOS',
        }),
      );
    } catch (e) {
      print('Failed to register device: $e');
      rethrow;
    }
  }

  Future<void> unregisterDevice() async {
    try {
      String? token = _prefs.getString(_pushyTokenKey);
      if (token != null) {
        await http.post(
          Uri.parse(
              '${AppConfig.notificationApiUrl}/api/notifications/unregister'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'deviceToken': token,
          }),
        );
        await _prefs.remove(_pushyTokenKey);
      }
    } catch (e) {
      print('Failed to unregister device: $e');
      rethrow;
    }
  }
}
