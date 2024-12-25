import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';

class AuthService {
  static const String baseUrl = 'https://auth.alerthawk.net/api/auth';
  final SharedPreferences _prefs;
  final GlobalKey<NavigatorState> _navigatorKey;
  late final AadOAuth _oauth;

  AuthService(this._prefs, this._navigatorKey) {
    final config = Config(
      tenant: '326ac626-dcd5-4409-be50-481d4c0316e4',
      clientId: 'e6cc6189-3b58-4c15-a1c4-e24e9f5e4a97',
      scope: 'openid profile email',
      redirectUri: 'msauth.net.alerthawk://auth',
      navigatorKey: _navigatorKey,
    );
    _oauth = AadOAuth(config);
  }

  Future<bool> loginWithCredentials(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
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
    await _prefs.clear();
    await _oauth.logout();
  }

  bool isAuthenticated() {
    return _prefs.containsKey('auth_token');
  }
}
