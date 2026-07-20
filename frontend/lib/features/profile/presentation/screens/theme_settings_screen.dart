import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_event_app/core/theme/theme_provider.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final currentMode = themeProvider.themeMode;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Theme',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: SafeArea(
        child: RadioGroup<ThemeMode>(
          groupValue: currentMode,
          onChanged: (mode) {
            if (mode != null) themeProvider.setThemeMode(mode);
          },
          child: Column(
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('System'),
                subtitle: const Text('Follow device settings'),
                secondary: const Icon(Icons.brightness_auto),
                value: ThemeMode.system,
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                subtitle: const Text('Light background'),
                secondary: const Icon(Icons.light_mode),
                value: ThemeMode.light,
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                subtitle: const Text('Dark background'),
                secondary: const Icon(Icons.dark_mode),
                value: ThemeMode.dark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
