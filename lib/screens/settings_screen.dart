import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../widgets/theme_selector_modal.dart';
import '../widgets/app_ui.dart';
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
  late final TextEditingController _metricsApiController =
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
    _metricsApiController.dispose();
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
      _metricsApiController.text =
          prefs.getString('metrics_api_url') ?? AppConfig.metricsApiUrl;
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
      await prefs.setString('metrics_api_url', _metricsApiController.text);
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
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'The app will now log out to apply the new settings.',
              style: GoogleFonts.inter(),
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
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
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
        _metricsApiController.text = settings['metrics_api_url'] ?? '';
        _azureTenantController.text = settings['azure_ad_tenant'] ?? '';
        _azureClientIdController.text = settings['azure_ad_client_id'] ?? '';
        _authKeyController.text = settings['auth_api_key'] ?? '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings loaded from QR code')),
      );
    }
  }

  Future<void> _deleteUser() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(),
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
              style: GoogleFonts.inter(),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            tooltip: 'Select theme',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => showThemeSelectorModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSettingsGroup(
                  title: 'API endpoints',
                  icon: Icons.cloud_outlined,
                  children: [
                    _field(_monitoringApiController, 'Monitoring API URL'),
                    _field(_authApiController, 'Auth API URL'),
                    _field(_notificationApiController, 'Notification API URL'),
                    _field(_metricsApiController, 'Metrics API URL',
                        last: true),
                  ],
                ),
                const SizedBox(height: 16),
                AppSettingsGroup(
                  title: 'Authentication',
                  icon: Icons.vpn_key_outlined,
                  children: [
                    _field(_authKeyController, 'Auth API Key'),
                    _field(_azureTenantController, 'Azure AD Tenant'),
                    _field(_azureClientIdController, 'Azure AD Client ID',
                        last: true),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _saveSettings,
                  icon: _isLoading
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(_isLoading ? 'Saving…' : 'Save settings'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _scanQRCode,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: const Text('Scan QR code'),
                ),
                if (_isLoggedIn) ...[
                  const SizedBox(height: 28),
                  Text(
                    'Danger zone',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _deleteUser,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    icon: const Icon(Icons.delete_forever_rounded, size: 18),
                    label: const Text('Delete my account'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label,
      {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 8 : 14),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
