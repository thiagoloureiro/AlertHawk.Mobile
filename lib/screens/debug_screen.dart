import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug info'),
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

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _buildSection(context, 'User email', userEmail),
              const SizedBox(height: 12),
              _buildSection(context, 'Auth token', authToken),
              const SizedBox(height: 12),
              _buildSection(context, 'Pushy token', pushyToken),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String value) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              value,
              style: GoogleFonts.inter(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
