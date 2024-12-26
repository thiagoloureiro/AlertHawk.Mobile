import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension HttpResponseExtension on http.Response {
  void handleUnauthorized(BuildContext context) async {
    if (statusCode == 401) {
      // Clear stored token
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Navigate to login screen
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }
}
