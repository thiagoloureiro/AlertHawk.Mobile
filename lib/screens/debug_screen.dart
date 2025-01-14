import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Debug Info',
          style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final prefs = snapshot.data!;
          final userEmail = prefs.getString('user_email') ?? 'Not found';
          final authToken = prefs.getString('auth_token') ?? 'Not found';
          final pushyToken = prefs.getString('deviceToken') ?? 'Not found';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('User Email', userEmail),
                const SizedBox(height: 24),
                _buildSection('Auth Token', authToken),
                const SizedBox(height: 24),
                _buildSection('Pushy Token', pushyToken),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.robotoMono(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SelectableText(
          value,
          style: GoogleFonts.robotoMono(fontSize: 14),
        ),
      ],
    );
  }
}
