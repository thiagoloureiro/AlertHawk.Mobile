import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import '../config/app_config.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  final SharedPreferences _prefs;
  final GlobalKey<NavigatorState> _navigatorKey;
  late final AadOAuth _oauth;

  AuthService(this._prefs, this._navigatorKey) {
    final config = Config(
      tenant: AppConfig.azureAdTenant,
      clientId: AppConfig.azureAdClientId,
      scope: 'openid profile email https://graph.microsoft.com/User.Read',
      redirectUri: 'msauth.net.alerthawk://auth',
      navigatorKey: _navigatorKey,
    );
    _oauth = AadOAuth(config);
  }

  Future<bool> loginWithCredentials(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.authApiUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final token = json.decode(response.body)['token'];
        await _prefs.setString('auth_token', token);
        await _updateDeviceToken();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> loginWithMSAL() async {
    try {
      await _oauth.logout();
      await _oauth.login();
      final graphToken = await _oauth.getAccessToken();

      if (graphToken != null) {
        final graphResponse = await http.get(
          Uri.parse('https://graph.microsoft.com/v1.0/me'),
          headers: {
            'Authorization': 'Bearer $graphToken',
            'Content-Type': 'application/json',
          },
        );

        if (graphResponse.statusCode == 200) {
          final userData = json.decode(graphResponse.body);
          final userEmail = userData['userPrincipalName'] ?? userData['mail'];

          final apiResponse = await http.post(
            Uri.parse('${AppConfig.authApiUrl}/api/auth/azure'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'apikey': AppConfig.authApiKey,
              'email': userEmail,
            }),
          );

          if (apiResponse.statusCode == 200) {
            final apiToken = json.decode(apiResponse.body)['token'];
            await _prefs.setString('auth_token', apiToken);
            await _prefs.setString('user_email', userEmail);
            await _updateDeviceToken();
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      await _oauth.logout();
      return false;
    }
  }

  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      await http.post(
        Uri.parse('${AppConfig.authApiUrl}/api/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    }
    await _oauth.logout();
  }

  bool isAuthenticated() {
    return _prefs.containsKey('auth_token');
  }

  Future<String?> getToken() async {
    return _prefs.getString('auth_token');
  }

  Future<String?> getUserEmail() async {
    return _prefs.getString('user_email');
  }

  Future<void> _updateDeviceToken() async {
    try {
      final deviceToken = _prefs.getString('deviceToken');
      final token = _prefs.getString('auth_token');

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
    } catch (e) {}
  }

  Future<bool> loginWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken != null) {
        final Map<String, dynamic> decodedToken =
            JwtDecoder.decode(credential.identityToken!);
        final String? email = decodedToken['email'];

        final apiResponse = await http.post(
          Uri.parse('${AppConfig.authApiUrl}/api/auth/azure'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'apikey': AppConfig.authApiKey,
            'email': email,
          }),
        );

        if (apiResponse.statusCode == 200) {
          final apiToken = json.decode(apiResponse.body)['token'];
          await _prefs.setString('auth_token', apiToken);
          await _prefs.setString('user_email', email!);
          await _updateDeviceToken();
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
