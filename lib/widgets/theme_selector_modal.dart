import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';

/// Shows a modal bottom sheet to pick app theme (Light, Dark, GitHub Dark, Monokai).
void showThemeSelectorModal(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    builder: (context) => const _ThemeSelectorSheet(),
  );
}

class _ThemeSelectorSheet extends StatelessWidget {
  const _ThemeSelectorSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'Appearance',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return Column(
                  children: AppThemeMode.values.map((mode) {
                    final isSelected = themeProvider.themeMode == mode;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Material(
                        color: isSelected
                            ? theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.7)
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppColors.radiusSm),
                        child: ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _swatch(mode),
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Icon(
                              _iconFor(mode),
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            _displayName(mode),
                            style: GoogleFonts.inter(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            _subtitle(mode),
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                          onTap: () {
                            themeProvider.setThemeMode(mode);
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode_rounded;
      case AppThemeMode.dark:
        return Icons.dark_mode_rounded;
      case AppThemeMode.githubDark:
        return Icons.code_rounded;
      case AppThemeMode.monokai:
        return Icons.palette_rounded;
    }
  }

  String _displayName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.githubDark:
        return 'GitHub Dark';
      case AppThemeMode.monokai:
        return 'Monokai';
    }
  }

  String _subtitle(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Bright and airy';
      case AppThemeMode.dark:
        return 'Dim gray surfaces';
      case AppThemeMode.githubDark:
        return 'Code-inspired blues';
      case AppThemeMode.monokai:
        return 'Warm editor palette';
    }
  }

  List<Color> _swatch(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return const [Color(0xFF2563EB), Color(0xFF93C5FD)];
      case AppThemeMode.dark:
        return const [Color(0xFF111827), Color(0xFF60A5FA)];
      case AppThemeMode.githubDark:
        return const [Color(0xFF0D1117), Color(0xFF58A6FF)];
      case AppThemeMode.monokai:
        return const [Color(0xFF272822), Color(0xFFFD971F)];
    }
  }
}
