import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../screens/qr_scanner_screen.dart';
import 'package:http/http.dart' as http;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _monitoringApiController =
      TextEditingController();
  late final TextEditingController _authApiController = TextEditingController();
  late final TextEditingController _notificationApiController =
      TextEditingController();
  late final TextEditingController _authKeyController = TextEditingController();
  late final TextEditingController _azureTenantController =
      TextEditingController();
  late final TextEditingController _azureClientIdController =
      TextEditingController();
  bool _isLoading = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _monitoringApiController.dispose();
    _authApiController.dispose();
    _notificationApiController.dispose();
    _authKeyController.dispose();
    _azureTenantController.dispose();
    _azureClientIdController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _monitoringApiController.text =
          prefs.getString('monitoring_api_url') ?? AppConfig.monitoringApiUrl;
      _authApiController.text =
          prefs.getString('auth_api_url') ?? AppConfig.authApiUrl;
      _notificationApiController.text =
          prefs.getString('notification_api_url') ??
              AppConfig.notificationApiUrl;
      _authKeyController.text =
          prefs.getString('auth_api_key') ?? AppConfig.authApiKey;
      _azureTenantController.text =
          prefs.getString('azure_ad_tenant') ?? AppConfig.azureAdTenant;
      _azureClientIdController.text =
          prefs.getString('azure_ad_client_id') ?? AppConfig.azureAdClientId;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'monitoring_api_url', _monitoringApiController.text);
      await prefs.setString('auth_api_url', _authApiController.text);
      await prefs.setString(
          'notification_api_url', _notificationApiController.text);
      await prefs.setString('auth_api_key', _authKeyController.text);
      await prefs.setString('azure_ad_tenant', _azureTenantController.text);
      await prefs.setString(
          'azure_ad_client_id', _azureClientIdController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );

        // Clear auth token
        await prefs.remove('auth_token');

        // Show a dialog informing the user
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(
              'Settings Updated',
              style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'The app will now log out to apply the new settings.',
              style: GoogleFonts.robotoMono(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to login screen and clear navigation stack
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                },
                child: Text(
                  'OK',
                  style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _scanQRCode() async {
    final settings = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
    );

    if (settings != null) {
      setState(() {
        _monitoringApiController.text = settings['monitoring_api_url'] ?? '';
        _authApiController.text = settings['auth_api_url'] ?? '';
        _notificationApiController.text =
            settings['notification_api_url'] ?? '';
        _azureTenantController.text = settings['azure_ad_tenant'] ?? '';
        _azureClientIdController.text = settings['azure_ad_client_id'] ?? '';
        _authKeyController.text = settings['auth_api_key'] ?? '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings loaded from QR code')),
      );
    }
  }

  Future<bool> _isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }

  Future<void> _deleteUser() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: GoogleFonts.robotoMono(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.robotoMono(),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.robotoMono(),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');

        if (token == null) {
          throw Exception('Not authenticated');
        }

        final response = await http.delete(
          Uri.parse('${AppConfig.authApiUrl}/api/User/delete'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          // Clear all auth-related data
          await prefs.remove('auth_token');
          await prefs.remove('user_email');
          await prefs.remove('deviceToken');

          if (mounted) {
            // Show success message and navigate to login
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate to login screen and clear navigation stack
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
        } else {
          throw Exception('Failed to delete account');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete account'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.containsKey('auth_token');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _monitoringApiController,
                  decoration: InputDecoration(
                    labelText: 'Monitoring API URL',
                    labelStyle: GoogleFonts.robotoMono(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: GoogleFonts.robotoMono(),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter Monitoring API URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _authApiController,
                  decoration: InputDecoration(
                    labelText: 'Auth API URL',
                    labelStyle: GoogleFonts.robotoMono(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: GoogleFonts.robotoMono(),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter Auth API URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notificationApiController,
                  decoration: InputDecoration(
                    labelText: 'Notification API URL',
                    labelStyle: GoogleFonts.robotoMono(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: GoogleFonts.robotoMono(),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter Notification API URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _authKeyController,
                  decoration: InputDecoration(
                    labelText: 'Auth API Key',
                    labelStyle: GoogleFonts.robotoMono(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: GoogleFonts.robotoMono(),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter Auth API Key';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _azureTenantController,
                  decoration: InputDecoration(
                    labelText: 'Azure AD Tenant',
                    labelStyle: GoogleFonts.robotoMono(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: GoogleFonts.robotoMono(),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter Azure AD Tenant';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _azureClientIdController,
                  decoration: InputDecoration(
                    labelText: 'Azure AD Client ID',
                    labelStyle: GoogleFonts.robotoMono(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: GoogleFonts.robotoMono(),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter Azure AD Client ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDarkMode ? Colors.blue[700] : Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Save Settings',
                          style: GoogleFonts.robotoMono(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _scanQRCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDarkMode ? Colors.grey[700] : Colors.grey[200],
                    foregroundColor: isDarkMode ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(
                    'Read QR Code',
                    style: GoogleFonts.robotoMono(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isLoggedIn) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _deleteUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.delete_forever),
                    label: Text(
                      'Delete My Account',
                      style: GoogleFonts.robotoMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
