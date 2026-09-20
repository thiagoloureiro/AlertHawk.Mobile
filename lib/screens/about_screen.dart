import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../games/snake_game.dart';
import '../screens/debug_screen.dart';
import '../theme/app_colors.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late Future<String> _version;
  int _tapCount = 0;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    _version = _getAppVersion();
  }

  Future<String> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      _tapCount++;
                      _tapTimer?.cancel();
                      _tapTimer = Timer(const Duration(seconds: 2), () {
                        _tapCount = 0;
                      });

                      if (_tapCount >= 6) {
                        _tapCount = 0;
                        _tapTimer?.cancel();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const DebugScreen()),
                        );
                      }
                    },
                    child: Image.asset(
                      'assets/logo.png',
                      width: 112,
                      height: 112,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      _tapCount++;
                      _tapTimer?.cancel();
                      _tapTimer = Timer(const Duration(seconds: 2), () {
                        _tapCount = 0;
                      });

                      if (_tapCount >= 5) {
                        _tapCount = 0;
                        _tapTimer?.cancel();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SnakeGame()),
                        );
                      }
                    },
                    child: Text(
                      'AlertHawk',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<String>(
                    future: _version,
                    builder: (context, snapshot) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(AppColors.radiusXs),
                        ),
                        child: Text(
                          'Version ${snapshot.data ?? '…'}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _linkTile(
                  context,
                  icon: Icons.code_rounded,
                  title: 'GitHub project',
                  subtitle: 'Source code and issues',
                  url:
                      'https://github.com/thiagoloureiro/AlertHawk.Mobile',
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: theme.colorScheme.outlineVariant,
                ),
                _linkTile(
                  context,
                  icon: Icons.new_releases_outlined,
                  title: 'Release notes',
                  subtitle: 'What changed in each version',
                  url:
                      'https://github.com/thiagoloureiro/AlertHawk.Mobile/releases',
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: theme.colorScheme.outlineVariant,
                ),
                _linkTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy notice',
                  subtitle: 'How we handle your data',
                  url: 'https://alerthawk.net/privacy.html',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String url,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.open_in_new_rounded,
        size: 16,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: () => _launchUrl(url),
    );
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }
}
