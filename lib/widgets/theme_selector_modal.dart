import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Select theme',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return Column(
                  children: AppThemeMode.values.map((mode) {
                    final isSelected = themeProvider.themeMode == mode;
                    return ListTile(
                      leading: Icon(
                        _iconFor(mode),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(_displayName(mode)),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        themeProvider.setThemeMode(mode);
                        Navigator.of(context).pop();
                      },
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
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.githubDark:
        return Icons.code;
      case AppThemeMode.monokai:
        return Icons.palette;
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
}
