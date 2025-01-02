import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/welcome_screen.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _hasChanges = false;
  final TextEditingController _durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _durationController.text =
          (prefs.getInt('refresh_duration') ?? 30).toString();
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);

    // Save refresh duration if valid
    final duration = int.tryParse(_durationController.text);
    if (duration != null && duration >= 10 && duration <= 999) {
      await prefs.setInt('refresh_duration', duration);
    }

    Navigator.of(context).pop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  bool _isValidDuration(String value) {
    final duration = int.tryParse(value);
    return duration != null && duration >= 10 && duration <= 999;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) => SwitchListTile(
                    title: Text(
                      'Dark Mode',
                      style: GoogleFonts.robotoMono(),
                    ),
                    subtitle: Text(
                      'Enable dark theme',
                      style: GoogleFonts.robotoMono(fontSize: 12),
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (bool value) {
                      Provider.of<ThemeProvider>(context, listen: false)
                          .toggleTheme();
                    },
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(
                    'Notifications',
                    style: GoogleFonts.robotoMono(),
                  ),
                  subtitle: Text(
                    'Show notifications when monitor status changes',
                    style: GoogleFonts.robotoMono(fontSize: 12),
                  ),
                  value: _notificationsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _notificationsEnabled = value;
                      _hasChanges = true;
                    });
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _durationController,
                    enabled: _notificationsEnabled,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Auto Refresh Duration (seconds)',
                      labelStyle: GoogleFonts.robotoMono(),
                      helperText: 'Value between 10 and 999 seconds',
                      helperStyle: GoogleFonts.robotoMono(fontSize: 12),
                      errorText: _durationController.text.isNotEmpty &&
                              !_isValidDuration(_durationController.text)
                          ? 'Please enter a value between 10 and 999'
                          : null,
                      errorStyle: GoogleFonts.robotoMono(fontSize: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: _hasChanges ? _saveSettings : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue[700]
                              : Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text(
                      'Save Settings',
                      style: GoogleFonts.robotoMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
