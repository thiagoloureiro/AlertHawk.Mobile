import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/auth_service.dart';
import 'welcome_screen.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'settings_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'dart:io' show Platform;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _repeatPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'AlertHawk',
          style: GoogleFonts.robotoMono(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 2),
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/logo.png',
                      height: 120,
                      width: 120,
                    ),
                  ),
                  const SizedBox(height: 0),
                  // Login Form
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black26
                              : Colors.grey.withOpacity(0.1),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Login',
                          style: GoogleFonts.robotoMono(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.blue[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              labelStyle: GoogleFonts.robotoMono(
                                color: isDarkMode
                                    ? Colors.blue[200]
                                    : Colors.blue[400],
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: isDarkMode
                                    ? Colors.blue[200]
                                    : Colors.blue[400],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDarkMode
                                      ? Colors.blue[200]!
                                      : Colors.blue[400]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDarkMode
                                      ? Colors.blue[200]!
                                      : Colors.blue[400]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDarkMode
                                      ? Colors.blue[200]!
                                      : Colors.blue[400]!,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              filled: true,
                              fillColor: isDarkMode
                                  ? Colors.blue.withOpacity(0.05)
                                  : Colors.blue.withOpacity(0.03),
                              errorStyle: GoogleFonts.robotoMono(height: 0.5),
                              isDense: true,
                            ),
                            style: GoogleFonts.robotoMono(),
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Please enter username';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: GoogleFonts.robotoMono(
                                color: isDarkMode
                                    ? Colors.blue[200]
                                    : Colors.blue[400],
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: isDarkMode
                                    ? Colors.blue[200]
                                    : Colors.blue[400],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDarkMode
                                      ? Colors.blue[200]!
                                      : Colors.blue[400]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDarkMode
                                      ? Colors.blue[200]!
                                      : Colors.blue[400]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDarkMode
                                      ? Colors.blue[200]!
                                      : Colors.blue[400]!,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              filled: true,
                              fillColor: isDarkMode
                                  ? Colors.blue.withOpacity(0.05)
                                  : Colors.blue.withOpacity(0.03),
                              errorStyle: GoogleFonts.robotoMono(height: 0.5),
                              isDense: true,
                            ),
                            style: GoogleFonts.robotoMono(),
                            obscureText: true,
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Please enter password';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: isDarkMode
                                ? Colors.blue[700]
                                : Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(
                                  'Login',
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => _showRegisterDialog(),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Register',
                                style: GoogleFonts.robotoMono(
                                  color: isDarkMode
                                      ? Colors.blue[200]
                                      : Theme.of(context).primaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showForgotPasswordDialog(),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.robotoMono(
                                  color: isDarkMode
                                      ? Colors.blue[200]
                                      : Theme.of(context).primaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 10),
                        Text(
                          'Or continue with',
                          style: GoogleFonts.robotoMono(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleMSALLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? Colors.blue[800]
                                : Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: isDarkMode
                                  ? const BorderSide(color: Colors.white30)
                                  : BorderSide.none,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FaIcon(FontAwesomeIcons.microsoft,
                                  size: 20, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Sign in with Microsoft',
                                style: GoogleFonts.robotoMono(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!Platform.isAndroid)
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleAppleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const FaIcon(FontAwesomeIcons.apple, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Sign in with Apple',
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: Text(
                      'Settings',
                      style: GoogleFonts.robotoMono(),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final success = await AuthService(
        await SharedPreferences.getInstance(),
        navigatorKey,
      ).loginWithCredentials(
        _usernameController.text,
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed')),
        );
      }
    }
  }

  Future<void> _handleMSALLogin() async {
    setState(() => _isLoading = true);

    final success = await AuthService(
      await SharedPreferences.getInstance(),
      navigatorKey,
    ).loginWithMSAL();

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MSAL login failed')),
      );
    }
  }

  Future<void> _handleAppleLogin() async {
    setState(() => _isLoading = true);

    final success = await AuthService(
      await SharedPreferences.getInstance(),
      navigatorKey,
    ).loginWithApple();

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apple login failed')),
      );
    }
  }

  void _showRegisterDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Register',
            style: GoogleFonts.robotoMono(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStyledField(
                      controller: _usernameController,
                      label: 'Name',
                      icon: Icons.person_outline,
                      isDarkMode:
                          Theme.of(context).brightness == Brightness.dark,
                      validator: (value) {
                        if (value?.isEmpty ?? true)
                          return 'Please enter your name';
                        if ((value?.length ?? 0) < 3)
                          return 'Name must be at least 3 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildStyledField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      isDarkMode:
                          Theme.of(context).brightness == Brightness.dark,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Please enter email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value!)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildStyledField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      isDarkMode:
                          Theme.of(context).brightness == Brightness.dark,
                      isPassword: true,
                      validator: (value) {
                        if (value?.isEmpty ?? true)
                          return 'Please enter password';
                        if ((value?.length ?? 0) < 6)
                          return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildStyledField(
                      controller: _repeatPasswordController,
                      label: 'Repeat Password',
                      icon: Icons.lock_outline,
                      isDarkMode:
                          Theme.of(context).brightness == Brightness.dark,
                      isPassword: true,
                      validator: (value) {
                        if (value?.isEmpty ?? true)
                          return 'Please repeat password';
                        if (value != _passwordController.text)
                          return 'Passwords do not match';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: GoogleFonts.robotoMono()),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (formKey.currentState?.validate() ?? false) {
                              setState(() => isLoading = true);
                              try {
                                final response = await http.post(
                                  Uri.parse(
                                      '${AppConfig.authApiUrl}/api/user/create'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({
                                    'username': _usernameController.text,
                                    'password': _passwordController.text,
                                    'repeatPassword':
                                        _repeatPasswordController.text,
                                    'userEmail': _emailController.text,
                                  }),
                                );

                                if (response.statusCode == 200) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Registration successful!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  final error = jsonDecode(response.body);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(error['content'] ??
                                          'Registration failed'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Network error occurred'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } finally {
                                setState(() => isLoading = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? Colors.blue[700]
                          : Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Register',
                            style: GoogleFonts.robotoMono(
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for styled form fields
  Widget _buildStyledField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDarkMode,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      height: 48,
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.robotoMono(
            color: isDarkMode ? Colors.blue[200] : Colors.blue[400],
          ),
          prefixIcon: Icon(
            icon,
            color: isDarkMode ? Colors.blue[200] : Colors.blue[400],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.blue[200]! : Colors.blue[400]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.blue[200]! : Colors.blue[400]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.blue[200]! : Colors.blue[400]!,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: isDarkMode
              ? Colors.blue.withOpacity(0.05)
              : Colors.blue.withOpacity(0.03),
          errorStyle: GoogleFonts.robotoMono(height: 0.5),
          isDense: true,
        ),
        style: GoogleFonts.robotoMono(),
        validator: validator,
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Forgot Password',
          style: GoogleFonts.robotoMono(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Form(
                key: formKey,
                child: _buildStyledField(
                  controller: emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  isDarkMode: isDarkMode,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter email';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value!)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.robotoMono(
                    color: isDarkMode ? Colors.blue[200] : Colors.blue[400],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (formKey.currentState?.validate() ?? false) {
                          setState(() => isLoading = true);
                          try {
                            final response = await http.post(
                              Uri.parse(
                                  '${AppConfig.authApiUrl}/api/user/resetpassword/${emailController.text}'),
                            );

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  response.statusCode == 200
                                      ? 'Password reset email sent!'
                                      : 'Failed to reset password',
                                ),
                                backgroundColor: response.statusCode == 200
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Network error occurred'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            setState(() => isLoading = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? Colors.blue[700]
                      : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Reset Password',
                        style:
                            GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
