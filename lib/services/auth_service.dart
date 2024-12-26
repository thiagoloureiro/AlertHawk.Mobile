import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import '../config/app_config.dart';

class AuthService {
  final SharedPreferences _prefs;
  final GlobalKey<NavigatorState> _navigatorKey;
  late final AadOAuth _oauth;

  AuthService(this._prefs, this._navigatorKey) {
    final config = Config(
      tenant: AppConfig.azureAdTenant,
      clientId: AppConfig.azureAdClientId,
      scope: 'openid profile email',
      redirectUri: 'msauth.net.alerthawk://auth',
      navigatorKey: _navigatorKey,
    );
    _oauth = AadOAuth(config);
  }

  Future<bool> loginWithCredentials(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.authApiUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final token = json.decode(response.body)['token'];
        await _prefs.setString('auth_token', token);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> loginWithMSAL() async {
    try {
      await _oauth.login();
      final accessToken = await _oauth.getAccessToken();
      if (accessToken != null) {
        await _prefs.setString('auth_token', accessToken);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      await http.post(
        Uri.parse('${AppConfig.authApiUrl}/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    }
    await _prefs.clear();
    await _oauth.logout();
  }

  bool isAuthenticated() {
    return _prefs.containsKey('auth_token');
  }

  Future<String?> getToken() async {
    return _prefs.getString('auth_token');
  }
}
