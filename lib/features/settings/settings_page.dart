import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings & About',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Environment configuration and app info.'),
          const SizedBox(height: 16),
          const Text(
            'TODO: Add environment switcher (dev/prod), app metadata, and support links.',
          ),
        ],
      ),
    );
  }
}
