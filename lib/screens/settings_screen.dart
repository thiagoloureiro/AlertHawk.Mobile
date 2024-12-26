import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
      }
    } finally {
      setState(() => _isLoading = false);
    }
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
