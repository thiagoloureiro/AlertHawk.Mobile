import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../games/snake_game.dart';
import '../screens/debug_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About',
          style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
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
                      MaterialPageRoute(builder: (_) => const DebugScreen()),
                    );
                  }
                },
                child: Image.asset(
                  'assets/logo.png',
                  width: 150,
                  height: 150,
                ),
              ),
              const SizedBox(height: 16),
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
                  style: GoogleFonts.robotoMono(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FutureBuilder<String>(
                future: _version,
                builder: (context, snapshot) {
                  return Text(
                    'Version: ${snapshot.data ?? 'Loading...'}',
                    style: GoogleFonts.robotoMono(fontSize: 16),
                    textAlign: TextAlign.center,
                  );
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _launchUrl(
                    'https://github.com/thiagoloureiro/AlertHawk.Mobile'),
                child: Text(
                  'Check project on Github',
                  style: GoogleFonts.robotoMono(
                    fontSize: 16,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _launchUrl(
                    'https://github.com/thiagoloureiro/AlertHawk.Mobile/releases'),
                child: Text(
                  'Release Notes',
                  style: GoogleFonts.robotoMono(
                    fontSize: 16,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _launchUrl('https://alerthawk.net/privacy.html'),
                child: Text(
                  'Privacy Notice',
                  style: GoogleFonts.robotoMono(
                    fontSize: 16,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }
}
